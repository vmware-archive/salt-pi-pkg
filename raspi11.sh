#!/usr/bin/env bash

# Copyright 2021-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2

export DEB_BUILD_OPTIONS=nocheck
export DEBIAN_FRONTEND=noninteractive
export GNUPGHOME=/run/gpg
export DEBIAN_OS_VERSION_TARGET=11
export DEBIAN_OS_CODENAME_TARGET=bullseye
export PACKAGE_VERSION=3005.1
# Also expects the following vars:
# `GPG_PRIVATE_SIGNING_KEY`: Contents of a GPG key used for signing packages. Will be imported.
# `GPG_PASSPHRASE`: Passphrase for the imported GPG key.
# `SIGNING_KEY_FINGERPRINT`: The fingerprint reference of the imported signing key.

##
# Prep env
##
git clean -fdx
rm -rf ras${DEBIAN_OS_VERSION_TARGET}
mkdir ras${DEBIAN_OS_VERSION_TARGET}
cd ras${DEBIAN_OS_VERSION_TARGET}

##
# Download salt source
##
curl -fsSL https://github.com/saltstack/salt/archive/refs/tags/v${PACKAGE_VERSION}.tar.gz -o salt_${PACKAGE_VERSION}+ds.orig.tar.gz
tar -xf salt_${PACKAGE_VERSION}+ds.orig.tar.gz
pushd salt-${PACKAGE_VERSION}/

## Download debian package reqs
curl -fsSL https://raw.githubusercontent.com/saltstack/salt-pack-py3/develop/file_roots/pkg/salt/$(echo "${PACKAGE_VERSION}"|sed "s/\./_/g")/debian${DEBIAN_OS_VERSION_TARGET}/spec/salt_debian.tar.xz | tar -Jxvf -
debuild -us -uc
popd

RCLONE_CONFIG_S3_TYPE=s3 RCLONE_CONFIG_S3_PROVIDER=Other RCLONE_CONFIG_S3_ENV_AUTH=false RCLONE_CONFIG_S3_ENDPOINT=https://s3.repo.saltproject.io rclone sync --fast-list --use-server-modtime -v --exclude '/salt*dsc' --exclude '/salt*deb' --exclude '/salt*tar*' --exclude '/db**' --exclude '/pool**' --exclude '/dists**' s3:s3/py3/debian/${DEBIAN_OS_VERSION_TARGET}/armhf/latest/ ./repo/

##
# Package signing example
##
sudo rm -rf /run/gpg
sudo install -m 700 -o pi -g pi -d "${GNUPGHOME}"
echo -e "use-agent\npinentry-mode loopback" > "${GNUPGHOME}/gpg.conf"
echo -e "allow-preset-passphrase\nallow-loopback-pinentry" > "${GNUPGHOME}/gpg-agent.conf"
gpgconf --kill gpg-agent
export GPG_TTY=$(tty)
gpg --batch --no-tty --import <(echo "${GPG_PRIVATE_SIGNING_KEY}")
TEMPFILE=`mktemp`
echo `date` > $TEMPFILE
gpg --batch --no-tty --passphrase-file <(echo "${GPG_PASSPHRASE}") --clearsign -a --output /dev/null $TEMPFILE
rm -f $TEMPFILE
debsign -k ${SIGNING_KEY_FINGERPRINT} salt*.dsc
mkdir -p repo/conf
cd repo
if [ -d /tmp/new-deps ]; then for i in /tmp/new-deps/*.dsc; do debsign -k ${SIGNING_KEY_FINGERPRINT} "${i}" ; done ;  cp -v /tmp/new-deps/* ./ ; fi
cp -v ../salt*tar* ../salt*dsc ../salt*deb ./
echo -e 'Origin: SaltStack\nLabel: salt_debian11\nSuite: stable\nCodename: bullseye\nArchitectures: armhf source\nComponents: main\nDescription: SaltStack Debian 11 Python 3 package repo' > conf/distributions
echo "SignWith: ${SIGNING_KEY_FINGERPRINT}" >> conf/distributions
echo -e 'ask-passphrase' > conf/options

##
# Test install
##
for i in *.deb; do reprepro --ignore=wrongdistribution --component=main -Vb . includedeb ${DEBIAN_OS_CODENAME_TARGET} $i; done
for i in *.dsc; do reprepro --ignore=wrongdistribution --component=main -Vb . includedsc ${DEBIAN_OS_CODENAME_TARGET} $i; done
echo deb file://$PWD ${DEBIAN_OS_CODENAME_TARGET} main|sudo tee /etc/apt/sources.list.d/salt.list
sudo apt update
sudo apt -o DPkg::Options::=--force-confnew install --reinstall --allow-downgrades -y salt-master=${PACKAGE_VERSION}+ds-1 salt-minion=${PACKAGE_VERSION}+ds-1 salt-common=${PACKAGE_VERSION}+ds-1
sudo systemctl start salt-master
sleep 20
sudo systemctl start salt-minion
sleep 30
if ! sudo salt \* test.version -t 30 --output text|grep ${PACKAGE_VERSION}; then sudo systemctl stop salt-master salt-minion; exit 1; fi
sudo systemctl stop salt-master salt-minion

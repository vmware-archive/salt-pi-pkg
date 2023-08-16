# !!Project is Archived!!

> Salt Project / VMware has ended active development of this project, this repository will no longer be updated.

- These are example scripts referenced when previously building `armhf` Raspbian packages for Raspberry Pi devices.
- If using `arm64` Raspbian OS (64-bit OS on Raspberry Pi 3 and newer Pi devices), `arm64` [onedir-based builds](https://docs.saltproject.io/salt/install-guide/en/latest/topics/upgrade-to-onedir.html#what-is-onedir) would be a better alternative:
  - [Debian Install Directions](https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/debian.html)
  - Debian 10 `arm64` example repo directory base path: https://repo.saltproject.io/salt/py3/debian/10/arm64/
  - Debian 11 `arm64` example repo directory base path: https://repo.saltproject.io/salt/py3/debian/11/arm64/

# salt-pi-pkg

Unsupported, unmaintained example scripts for building "classic" (non-Tiamat, non-onedir, pre-3006.x) packages on the Raspberry Pi.

## Overview

Scripts exist for the following OS versions:

- Raspbian 10 (armhf / 32-bit)
- Raspbian 11 (armhf / 32-bit)

## Suggested Raspberry Pi Node Setup

### Prerequisites

For setting up the Raspberry Pi, it should be a base install of the lite/server version of Raspbian, then:

* Add an ssh key to /home/pi/.ssh/authorized_keys
* Disable passwords for sshd
* Install all needed packages

```bash
sudo apt install devscripts rclone jq dh-exec reprepro git curl -y
```

#### Signing packages

The build script examples include signing the build Raspbian packages. The example scripts contain references to the following variables:

* `GPG_PRIVATE_SIGNING_KEY`: Contents of a GPG key used for signing packages. Will be imported.
* `GPG_PASSPHRASE`: Passphrase for the imported GPG key.
* `SIGNING_KEY_FINGERPRINT`: The fingerprint reference of the imported signing key.

> **NOTE:** These scripts are only example scripts. Based on your CI/CD setup, or availability of keys used for signing your own packages, the approach to secure handling and usage of keys/creds should be evaluated and restricted where possible.

### Build & Run

Depending on OS target version, have the CI/CD run:

```bash
# Example: ./build-scripts/<os-version>.sh
# Raspbian 10
./raspi10.sh
```

## License

Apache License Version 2.0

- Copyright 2021-2023 VMware, Inc.
- SPDX-License-Identifier: Apache-2
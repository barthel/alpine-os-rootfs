# alpine-os-rootfs

Builds a minimal Alpine Linux base rootfs for use with Raspberry Pi image builders.

Supports the following architectures:

| Make target | Alpine arch | Use case |
|---|---|---|
| `armhf` | `armhf` (ARMv6+VFP) | Raspberry Pi Zero W |
| `arm64` | `aarch64` | Raspberry Pi 3B/4 (64-bit) |
| `amd64` | `x86_64` | Development / CI |

Alpine's `armhf` targets ARMv6+VFP — compatible with Pi Zero W (ARM1176JZF-S),
unlike Debian `armhf` which requires ARMv7.

## Prerequisites

- Docker

## Build

```bash
# Build Docker builder image
make build

# Build armhf rootfs (Pi Zero W)
make armhf

# Build all architectures
make all
```

Output is written to the current directory as `rootfs-{arch}-{version}.tar.gz`.

### Versioning

Pass `ALPINE_OS_VERSION` to tag the output:

```bash
ALPINE_OS_VERSION=0.1.0 make armhf
```

Default: `dirty`.

### Alpine version

Override the Alpine minirootfs version:

```bash
ALPINE_VERSION=3.21.0 make armhf
```

Default: `3.21.0`.

## Included packages

The rootfs includes:

- `bash`, `bash-completion`
- `openssh` (sshd enabled at boot)
- `chrony` (NTP, enabled at boot)
- `avahi` (mDNS, enabled at boot)
- `sudo`, `curl`, `wget`, `ca-certificates`
- `net-tools`, `util-linux`, `htop`, `procps`
- `shadow` (useradd/passwd)

## Differences from HypriotOS (Debian-based)

| Feature | HypriotOS | AlpineOS |
|---|---|---|
| Init system | systemd | OpenRC |
| Package manager | apt | apk |
| C library | glibc | musl |
| Locale support | yes | no |
| Default shell | bash | ash (busybox) |
| Bash | pre-installed | installed by rootfs build |
| Base size | ~300 MB | ~30 MB |

## Repository structure

```
Dockerfile              Builder container (Debian bookworm + QEMU)
Makefile                Build targets: armhf, arm64, amd64
builder/
  build.sh              Downloads Alpine minirootfs, runs chroot-script, packages tar.gz
  chroot-script.sh      apk installs, OpenRC service setup, hostname, os-release
  test.sh               Runs serverspec tests against the built rootfs
  files/
    etc/
      motd              Login banner
      issue             TTY login banner
      issue.net         SSH banner
      network/
        interfaces      eth0 DHCP (busybox ifupdown)
      skel/
        .bashrc         Bash aliases
        .profile        Login shell profile
        .bash_prompt    Colored prompt with architecture label
  test/
    rootfs_spec.rb      Serverspec tests
```

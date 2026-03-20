#!/bin/sh
# Runs inside the Alpine chroot under busybox ash — POSIX sh only.
set -ex

ALPINE_MINOR="$(echo "${ALPINE_VERSION}" | cut -d. -f1,2)"

# Configure Alpine package repositories
cat > /etc/apk/repositories << EOF
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MINOR}/main
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MINOR}/community
EOF

apk update

# Install base packages
apk add --no-cache \
  openrc \
  bash \
  bash-completion \
  ca-certificates \
  curl \
  wget \
  openssh \
  avahi \
  net-tools \
  sudo \
  tzdata \
  chrony \
  htop \
  util-linux \
  shadow \
  procps

# Generate SSH host keys
ssh-keygen -A

# Enable OpenRC services at default runlevel
rc-update add sshd default
rc-update add chronyd default
rc-update add networking default
rc-update add avahi-daemon default 2>/dev/null || true

# Set timezone to UTC
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo "UTC" > /etc/timezone

# Set hostname
echo "${ALPINE_HOSTNAME}" > /etc/hostname

# Ensure /etc/hostname is world-readable (required by some tools)
chmod 644 /etc/hostname

# Install skel files for root
cp /etc/skel/.bashrc /root/ 2>/dev/null || true
cp /etc/skel/.profile /root/ 2>/dev/null || true
cp /etc/skel/.bash_prompt /root/ 2>/dev/null || true

# Append AlpineOS version info to os-release
printf 'ALPINE_OS="AlpineOS/%s"\n' "${ALPINE_ARCH}" >> /etc/os-release
printf 'ALPINE_OS_VERSION="%s"\n' "${ALPINE_OS_VERSION}" >> /etc/os-release

# Clean package cache
rm -rf /var/cache/apk/*

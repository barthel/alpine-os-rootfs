#!/bin/bash
set -ex

# This script must run inside the Docker builder container only.
if [ ! -f /.dockerenv ]; then
  echo "ERROR: script works in Docker only!"
  exit 1
fi

ALPINE_HOSTNAME="${ALPINE_HOSTNAME:-alpine-black-pearl}"
ALPINE_ARCH="${ALPINE_ARCH:-armhf}"
ALPINE_VERSION="${ALPINE_VERSION:-3.21.0}"
ALPINE_OS_VERSION="${ALPINE_OS_VERSION:-dirty}"

ALPINE_MINOR="$(echo "${ALPINE_VERSION}" | cut -d. -f1,2)"
ROOTFS_DIR="/alpine-${ALPINE_ARCH}"
MINIROOTFS_FILE="alpine-minirootfs-${ALPINE_VERSION}-${ALPINE_ARCH}.tar.gz"
MINIROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MINOR}/releases/${ALPINE_ARCH}/${MINIROOTFS_FILE}"

# Cleanup
mkdir -p /workspace
rm -rf "${ROOTFS_DIR}"
mkdir -p "${ROOTFS_DIR}"

# Download Alpine minirootfs
echo "Downloading Alpine minirootfs ${ALPINE_VERSION} for ${ALPINE_ARCH}..."
wget -q "${MINIROOTFS_URL}" -O "/tmp/${MINIROOTFS_FILE}"
tar -xzf "/tmp/${MINIROOTFS_FILE}" -C "${ROOTFS_DIR}/"
rm -f "/tmp/${MINIROOTFS_FILE}"

# For cross-arch builds: register QEMU binfmt and copy static binary into rootfs
if [ -n "${QEMU_ARCH:-}" ]; then
  update-binfmts --enable "qemu-${QEMU_ARCH}" || true
  cp "/usr/bin/qemu-${QEMU_ARCH}-static" "${ROOTFS_DIR}/usr/bin/" 2>/dev/null || true
fi

# Ensure DNS resolves inside chroot
cp /etc/resolv.conf "${ROOTFS_DIR}/etc/resolv.conf"

# Copy builder overlay files into rootfs
cp -R /builder/files/* "${ROOTFS_DIR}/"

# Set up mount points for pseudo filesystems
mkdir -p "${ROOTFS_DIR}/proc" "${ROOTFS_DIR}/sys" "${ROOTFS_DIR}/dev/pts"
mount -o bind /dev "${ROOTFS_DIR}/dev"
mount -o bind /dev/pts "${ROOTFS_DIR}/dev/pts"
mount -t proc none "${ROOTFS_DIR}/proc"
mount -t sysfs none "${ROOTFS_DIR}/sys"

# Configure rootfs via chroot
chroot "${ROOTFS_DIR}" \
  /usr/bin/env \
  ALPINE_HOSTNAME="${ALPINE_HOSTNAME}" \
  ALPINE_VERSION="${ALPINE_VERSION}" \
  ALPINE_ARCH="${ALPINE_ARCH}" \
  ALPINE_OS_VERSION="${ALPINE_OS_VERSION}" \
  /bin/sh < /builder/chroot-script.sh

# Unmount pseudo filesystems
umount -lqn "${ROOTFS_DIR}/dev/pts" || true
umount -lqn "${ROOTFS_DIR}/dev"     || true
umount -lqn "${ROOTFS_DIR}/proc"    || true
umount -lqn "${ROOTFS_DIR}/sys"     || true

# Remove the QEMU binary — it belongs to the host, not the target rootfs
rm -f "${ROOTFS_DIR}"/usr/bin/qemu-*-static

# Restore a minimal resolv.conf (live system gets DNS from DHCP)
echo "nameserver 1.1.1.1" > "${ROOTFS_DIR}/etc/resolv.conf"

# Package rootfs tarball
umask 0000
pushd /workspace
ARCHIVE_NAME="rootfs-${ALPINE_ARCH}-${ALPINE_OS_VERSION}.tar.gz"
tar --exclude=dev --exclude=sys --exclude=proc \
    -czf "${ARCHIVE_NAME}" -C "${ROOTFS_DIR}/" .
sha256sum "${ARCHIVE_NAME}" > "${ARCHIVE_NAME}.sha256"
popd

# Run tests
ALPINE_HOSTNAME="${ALPINE_HOSTNAME}" ALPINE_ARCH="${ALPINE_ARCH}" /builder/test.sh

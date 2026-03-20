#!/bin/bash
set +ex

# This script must run inside a container only.
if [ ! -f /.dockerenv ] && [ ! -f /.containerenv ] && [ ! -f /run/.containerenv ]; then
  echo "ERROR: script works in Docker/Podman only!"
  exit 1
fi

ALPINE_ARCH="${ALPINE_ARCH:-armhf}"
ALPINE_OS_VERSION="${ALPINE_OS_VERSION:-dirty}"
ROOTFS_DIR="/alpine-${ALPINE_ARCH}"
ROOTFS_TAR="/workspace/rootfs-${ALPINE_ARCH}-${ALPINE_OS_VERSION}.tar.gz"

echo "Testing: ALPINE_ARCH=${ALPINE_ARCH}"
mkdir -p /workspace

if [ ! -d "${ROOTFS_DIR}" ]; then
  mkdir -p "${ROOTFS_DIR}"
  if [ ! -f "${ROOTFS_TAR}" ]; then
    echo "ERROR: rootfs tarfile ${ROOTFS_TAR} missing!"
    exit 1
  fi
  tar -xzf "${ROOTFS_TAR}" -C "${ROOTFS_DIR}/"
fi

cd "${ROOTFS_DIR}" && rspec --format documentation --color /builder/test

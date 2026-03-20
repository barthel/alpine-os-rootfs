#!/bin/bash
# build.sh — builds Alpine rootfs tarballs for armhf, aarch64, and x86_64.
#
# Usage:
#   ./build.sh                      # local build, BASE_TAG=latest, ALPINE_OS_VERSION=latest
#   VERSION=3.21.0 ./build.sh       # versioned build: BASE_TAG=3.21, ALPINE_OS_VERSION=3.21.0
#
# Environment:
#   VERSION           Release version tag, e.g. 3.21.0 (default: empty = latest)
#   ALPINE_HOSTNAME   Hostname baked into the rootfs (default: alpine-black-pearl)

set -e

ALPINE_HOSTNAME="${ALPINE_HOSTNAME:-alpine-black-pearl}"
IMAGE_NAME="alpine-rootfs-builder"

if [ -n "${VERSION}" ]; then
  BASE_TAG="${VERSION%.*}"       # major.minor, e.g. 3.21 from 3.21.0
  ALPINE_VERSION="${VERSION}"
  ALPINE_OS_VERSION="${VERSION}"
else
  BASE_TAG="latest"
  ALPINE_VERSION="3.21.0"
  ALPINE_OS_VERSION="latest"
fi

echo "Building ${IMAGE_NAME} (base: uwebarthel/alpine-image-builder:${BASE_TAG})..."
docker build --build-arg BASE_TAG="${BASE_TAG}" -t "${IMAGE_NAME}" .

DEFAULT_OPTS=(
  -e "ALPINE_HOSTNAME=${ALPINE_HOSTNAME}"
  -e "ALPINE_VERSION=${ALPINE_VERSION}"
  -e "ALPINE_OS_VERSION=${ALPINE_OS_VERSION}"
)

echo "Building rootfs for armhf..."
docker run --rm "${DEFAULT_OPTS[@]}" \
  -e ALPINE_ARCH=armhf \
  -e QEMU_ARCH=arm \
  -v "$(pwd):/workspace" \
  --privileged "${IMAGE_NAME}"

echo "Building rootfs for aarch64..."
docker run --rm "${DEFAULT_OPTS[@]}" \
  -e ALPINE_ARCH=aarch64 \
  -e QEMU_ARCH=aarch64 \
  -v "$(pwd):/workspace" \
  --privileged "${IMAGE_NAME}"

echo "Building rootfs for x86_64..."
docker run --rm "${DEFAULT_OPTS[@]}" \
  -e ALPINE_ARCH=x86_64 \
  -v "$(pwd):/workspace" \
  --privileged "${IMAGE_NAME}"

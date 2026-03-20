#!/bin/bash
# build.sh — builds Alpine rootfs tarballs for armhf, aarch64, and x86_64,
# and optionally pushes a Docker image to Docker Hub.
#
# Usage:
#   ./build.sh                          # local build only
#   PUSH=true ./build.sh                # build + push :latest to Docker Hub
#   VERSION=3.21.0 PUSH=true ./build.sh # versioned build + push all tags
#
# Environment:
#   DOCKER_USER   Docker Hub username (default: uwebarthel)
#   VERSION       Release version tag, e.g. 3.21.0 (default: empty = latest)
#   PUSH          Set to "true" to push the distribution image to Docker Hub

set -e

DOCKER_USER="${DOCKER_USER:-uwebarthel}"
DIST_IMAGE="${DOCKER_USER}/alpine-os-rootfs"
BUILD_IMAGE="alpine-rootfs-builder"
ALPINE_HOSTNAME="${ALPINE_HOSTNAME:-alpine-black-pearl}"

if [ -n "${VERSION}" ]; then
  BASE_TAG="${VERSION%.*}"       # major.minor, e.g. 3.21 from 3.21.0
  ALPINE_VERSION="${VERSION}"
  ALPINE_OS_VERSION="${VERSION}"
else
  BASE_TAG="latest"
  ALPINE_VERSION="3.21.0"
  ALPINE_OS_VERSION="latest"
fi

echo "Building ${BUILD_IMAGE} (base: ${DOCKER_USER}/alpine-image-builder:${BASE_TAG})..."
docker build --build-arg BASE_TAG="${BASE_TAG}" -t "${BUILD_IMAGE}" .

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
  --privileged "${BUILD_IMAGE}"

echo "Building rootfs for aarch64..."
docker run --rm "${DEFAULT_OPTS[@]}" \
  -e ALPINE_ARCH=aarch64 \
  -e QEMU_ARCH=aarch64 \
  -v "$(pwd):/workspace" \
  --privileged "${BUILD_IMAGE}"

echo "Building rootfs for x86_64..."
docker run --rm "${DEFAULT_OPTS[@]}" \
  -e ALPINE_ARCH=x86_64 \
  -v "$(pwd):/workspace" \
  --privileged "${BUILD_IMAGE}"

if [ "${PUSH:-false}" = "true" ]; then
  echo "Packaging rootfs tarballs into Docker distribution image..."

  # Copy tarballs into a staging dir, stripping the version suffix so the
  # image contents are stable across tags (version encoded in image tag).
  mkdir -p .dist-ctx
  for arch in armhf aarch64 x86_64; do
    cp "rootfs-${arch}-${ALPINE_OS_VERSION}.tar.gz" ".dist-ctx/rootfs-${arch}.tar.gz"
  done

  cat > .dist-ctx/Dockerfile << 'EOF'
FROM scratch
COPY rootfs-armhf.tar.gz    /rootfs/
COPY rootfs-aarch64.tar.gz  /rootfs/
COPY rootfs-x86_64.tar.gz   /rootfs/
CMD ["/noop"]
EOF

  docker build --tag "${DIST_IMAGE}:${ALPINE_OS_VERSION}" .dist-ctx/
  docker push "${DIST_IMAGE}:${ALPINE_OS_VERSION}"

  if [ -n "${VERSION}" ]; then
    MAJOR="${VERSION%%.*}"
    MINOR="${VERSION%.*}"
    PRE=""
    if [[ "${VERSION}" = *"rc"* ]]; then PRE="true"; fi
    if [ -z "${PRE}" ]; then
      for extra_tag in "${MINOR}" "${MAJOR}" latest stable; do
        docker tag "${DIST_IMAGE}:${ALPINE_OS_VERSION}" "${DIST_IMAGE}:${extra_tag}"
        docker push "${DIST_IMAGE}:${extra_tag}"
      done
    fi
  fi

  rm -rf .dist-ctx
  echo "Pushed ${DIST_IMAGE}:${ALPINE_OS_VERSION}"
fi

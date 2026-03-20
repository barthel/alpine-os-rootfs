ALPINE_VERSION  ?= 3.21.0
ALPINE_HOSTNAME ?= alpine-black-pearl

DEFAULT_OPTS = -e ALPINE_HOSTNAME=$(ALPINE_HOSTNAME) -e ALPINE_VERSION=$(ALPINE_VERSION) -e ALPINE_OS_VERSION

default: build

build:
	docker build -t alpine-rootfs-builder .

all: build armhf arm64 amd64

armhf: build
	docker run --rm $(DEFAULT_OPTS) \
	  -e ALPINE_ARCH=armhf \
	  -e QEMU_ARCH=arm \
	  -v $(shell pwd):/workspace \
	  --privileged alpine-rootfs-builder

arm64: build
	docker run --rm $(DEFAULT_OPTS) \
	  -e ALPINE_ARCH=aarch64 \
	  -e QEMU_ARCH=aarch64 \
	  -v $(shell pwd):/workspace \
	  --privileged alpine-rootfs-builder

amd64: build
	docker run --rm $(DEFAULT_OPTS) \
	  -e ALPINE_ARCH=x86_64 \
	  -v $(shell pwd):/workspace \
	  --privileged alpine-rootfs-builder

shell: build
	docker run --rm -ti $(DEFAULT_OPTS) \
	  -v $(shell pwd):/workspace \
	  --privileged alpine-rootfs-builder sh

test: build
	docker run --rm -ti \
	  -e ALPINE_ARCH=$(ALPINE_ARCH) \
	  -e ALPINE_HOSTNAME=$(ALPINE_HOSTNAME) \
	  -e ALPINE_OS_VERSION \
	  -v $(shell pwd):/workspace \
	  --privileged alpine-rootfs-builder /builder/test.sh

shellcheck: build
	docker run --rm -v $(shell pwd):/workspace alpine-rootfs-builder \
	  sh -c 'shellcheck builder/*.sh'

tag:
	git tag $(TAG)
	git push origin $(TAG)

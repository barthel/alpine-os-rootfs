FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    binfmt-support \
    qemu-user-static \
    curl \
    wget \
    ca-certificates \
    ruby-full \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && gem install serverspec --no-document

COPY builder /builder/

CMD ["/builder/build.sh"]

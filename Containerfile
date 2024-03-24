# podman run --rm -it -v "$PWD":/tmp/build:z -w /tmp/build golang:1.22-bookworm /bin/bash

FROM docker.io/golang:1.22-bookworm AS sdhcp-build
WORKDIR /tmp/build
RUN --mount=type=bind,target=/tmp/build,source=./3rdparty/sdhcp,rw=true make \
 && rm sdhcp \
 && gcc -s -static -o sdhcp sdhcp.c util.a

FROM docker.io/golang:1.22-bookworm AS linux-build
RUN apt-get update -yq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -yq flex bison bc libssl-dev \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /tmp/build
RUN --mount=type=bind,target=/tmp/build,source=./3rdparty/linux,rw=true make allnoconfig \
 && make kvm_guest.config \
 && make -j

FROM docker.io/golang:1.22-bookworm AS nomad-build
WORKDIR /tmp/build
RUN --mount=type=bind,target=/tmp/build,source=./3rdparty/nomad,rw=true go build

# FROM docker.io/golang:1.22-bookworm
# COPY --from=sdhcp-build /tmp/build/3rdparty/sdhcp/sdhcp /tmp/sdhcp
# COPY --from=linux-build /tmp/build/3rdparty/
# WORKDIR /tmp/build


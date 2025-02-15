FROM ghcr.io/ublue-os/ucore-minimal:stable-zfs

COPY usr /usr

COPY build.sh /tmp/build.sh

COPY --from=docker.io/mikefarah/yq:latest /usr/bin/yq /usr/bin/yq

RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    ostree container commit && \
    bootc container lint

FROM alpine:3.21.2 AS builder

ARG RECORDER_VERSION=0.9.9
# ARG RECORDER_VERSION=master

ENV DOCKER_RUNNING=1

RUN apk add --no-cache \
        make \
        gcc \
        git \
        shadow \
        musl-dev \
        curl-dev \
        libconfig-dev \
        mosquitto-dev \
        lmdb-dev \
        libsodium-dev \
        lua5.2-dev \
	util-linux-dev

RUN git clone --branch=${RECORDER_VERSION} https://github.com/owntracks/recorder /src/recorder
WORKDIR /src/recorder

COPY config.mk .
RUN make -j $(nprocs)
RUN make install DESTDIR=/app

FROM alpine:3.21.2

ENV DOCKER_RUNNING=1

VOLUME ["/store", "/config"]

RUN apk add --no-cache \
	curl \
	jq \
	libcurl \
	libconfig \
	mosquitto \
	lmdb \
	libsodium \
	lua5.2 \
	util-linux \
	tzdata

ENV TZ="UTC"

COPY recorder.conf /config/recorder.conf
COPY JSON.lua /config/JSON.lua

COPY --from=builder /app /

COPY recorder-health.sh /usr/sbin/recorder-health.sh
COPY entrypoint.sh /usr/sbin/entrypoint.sh

RUN chmod +x /usr/sbin/*.sh
RUN chmod +r /config/recorder.conf
RUN chmod 444 /config/timezone16.bin

# If you need health-checking, enable the option below.  If you are running
# systemd version 253 or newer, make sure to configure LogFilterPatterns to
# filter out the healthchecks from the system logs.
# https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#LogFilterPatterns=
# If you are running systemd version 252 or older, keep in mind that using the
# HEALTHCHECK feature will cause systemd to generate a significant amount of
# spam in the system logs.
# HEALTHCHECK CMD /usr/sbin/recorder-health.sh

EXPOSE 8083

# ENV OTR_CAFILE=/etc/ssl/cert.pem
ENV OTR_STORAGEDIR=/store
ENV OTR_TOPIC="owntracks/#"

ENTRYPOINT ["/usr/sbin/entrypoint.sh"]

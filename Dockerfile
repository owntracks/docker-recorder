FROM alpine
LABEL version="1.0" description="OwnTracks Recorder"
LABEL authors="Jan-Piet Mens <jpmens@gmail.com>, Giovanni Angoli <juzam76@gmail.com>, Amy Nagle <kabili@zyrenth.com>, Malte Deiseroth <mdeiseroth88@gmail.com>"
MAINTAINER Malte Deiseroth <mdeiseroth88@gmail.com>

COPY entrypoint.sh /entrypoint.sh
COPY config.mk /config.mk
COPY recorder.conf /etc/default/recorder.conf
COPY recorder-health.sh /usr/local/sbin/recorder-health.sh

ENV VERSION=0.8.1

RUN apk add --no-cache --virtual .build-deps \
        curl-dev libconfig-dev make \
        gcc musl-dev mosquitto-dev wget \
    && apk add --no-cache \
        libcurl libconfig-dev mosquitto-dev lmdb-dev libsodium-dev lua5.2-dev \
    && mkdir -p /usr/local/source \
    && cd /usr/local/source \
    && wget https://github.com/owntracks/recorder/archive/$VERSION.tar.gz \
    && tar xzf $VERSION.tar.gz \
    && cd recorder-$VERSION \
    && mv /config.mk ./ \
    && make \
    && make install \
    && cd / \
    && chmod 755 /entrypoint.sh \
    && rm -rf /usr/local/source \
    && chmod 755 /usr/local/sbin/recorder-health.sh \
    && apk del .build-deps
RUN apk add --no-cache \
	curl jq

VOLUME ["/store", "/config"]

COPY recorder.conf /config/recorder.conf

HEALTHCHECK CMD /usr/local/sbin/recorder-health.sh

EXPOSE 8083

ENTRYPOINT ["/entrypoint.sh"]

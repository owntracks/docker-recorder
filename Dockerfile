FROM alpine
LABEL version="1.0" description="OwnTracks Recorder"
LABEL authors="Jan-Piet Mens <jpmens@gmail.com>, Giovanni Angoli <juzam76@gmail.com>, Amy Nagle <kabili@zyrenth.com>, Malte Deiseroth <mdeiseroth88@gmail.com>"
MAINTAINER Malte Deiseroth <mdeiseroth88@gmail.com>

COPY entrypoint.sh /entrypoint.sh
COPY config.mk /config.mk
COPY recorder.conf /etc/default/recorder.conf

ENV VERSION=0.8.0

RUN apk add --no-cache --virtual .build-deps \
        curl-dev libconfig-dev make \
        gcc musl-dev mosquitto-dev wget \
    && apk add --no-cache \
        libcurl libconfig-dev mosquitto-dev lmdb-dev libsodium-dev lua5.2-dev openssl-dev \
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
    && apk del .build-deps

VOLUME ["/store", "/config"]

COPY recorder.conf /config/recorder.conf

EXPOSE 8083

ENTRYPOINT ["/entrypoint.sh"]

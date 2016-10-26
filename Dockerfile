FROM debian:jessie
LABEL version="0.4" description="Mosquitto and OwnTracks Recorder"
MAINTAINER Jan-Piet Mens <jpmens@gmail.com>

RUN apt-get update && apt-get install -y wget && \
	wget -q -O /tmp/owntracks.gpg.key http://repo.owntracks.org/repo.owntracks.org.gpg.key && \
	apt-key add /tmp/owntracks.gpg.key
RUN wget -q -O /tmp/mosquitto.gpg.key http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key && \
    apt-key add /tmp/mosquitto.gpg.key
RUN apt-get install -y software-properties-common && \
	apt-add-repository 'deb http://repo.owntracks.org/debian jessie main' && \
	apt-add-repository 'deb http://repo.mosquitto.org/debian jessie main' && \
	apt-get update && \
	apt-get install -y \
		libmosquitto1 \
		libsodium13 \
		libcurl3 \
		liblua5.2-0 \
		mosquitto \
		mosquitto-clients \
		supervisor \
		ot-recorder \
		&& \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# data volume
VOLUME /owntracks
COPY ot-recorder.default /etc/default/ot-recorder
RUN mkdir -p /var/log/supervisor && \
	mkdir -p -m 775 /owntracks/recorder/store && \
	chown -R owntracks:owntracks /owntracks
COPY launcher.sh /usr/local/sbin/launcher.sh
COPY generate-CA.sh /usr/local/sbin/generate-CA.sh
RUN chmod 755 /usr/local/sbin/launcher.sh /usr/local/sbin/generate-CA.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY mosquitto.conf mosquitto.acl /etc/mosquitto/

EXPOSE 1883 8883 8083
CMD ["/usr/local/sbin/launcher.sh"]

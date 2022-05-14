# Dockerfile for OwnTracks Recorder

[![Build Status](https://travis-ci.com/owntracks/docker-recorder.svg?branch=master)](https://travis-ci.com/owntracks/docker-recorder)

Dockerfile for the [Recorder](https://github.com/owntracks/recorder) of the
OwnTracks project. The image is [owntracks/recorder](https://hub.docker.com/r/owntracks/recorder).

## Quickstart

```bash
docker volume create recorder_store
docker run -d -p 8083:8083 -v recorder_store:/store -e OTR_HOST=mqtt_broker owntracks/recorder
```

Recorder is now accessible at `http://localhost:8083`.

`-p 8083:8083` makes the container reachable at port 8083. `-d` detaches the
container into the background. The volume `recorder_store` is mounted at
`/store` into the container. This is needed to have persistent data storage.
`-e` allows to pass additional configuration to the container as
environment variables. Multiple `-e` parameters can be used for multiple
environment variables.

## Configuration

The Recorder can be configured using two methods, environment variables and
via the a `recorder.conf` file in the `/config` volume of the container.

### Environment variables

Can be passed to the container with the `-e` parameter. Example:

```bash
docker run -d -p 8083:8083 \
        -e OTR_HOST=mqtt_broker \
        -e OTR_PORT=1883 \
        -e OTR_USER=user \
        -e OTR_PASS=pass \
        owntracks/recorder
```

The complete list of parameters can be found in the [recorder
documentation](https://github.com/owntracks/recorder/blob/master/README.md#configuration-file).

### Configuration file

One can also use a configuration file. The container reads a `recorder.conf`
file from the `/config` folder. To use this, create a folder e.g. `./config` and
mount it into you docker container at `/config`.

```bash
mkdir config
docker run -d -p 8083:8083 -v recorder_store:/store -v ./config:/config owntracks/recorder
```

Up on starting the recorder, a default `recorder.conf` file will be created if
none exists. Possible options are documented [here](https://github.com/owntracks/recorder/blob/master/README.md#configuration-file).

**Notes:**

- The value of `OTR_HOST` is as seen from the container. Thus `localhost` refers to
the container not the host and should likely not be used.
- Environment variables, overwrite the `recorder.conf` file options.
- The shell like style of the`recorder.conf` file needs `""` encapsulated
variable values.

## Storing data

The `/store` volume of the container is used for persistent storage of location
data. The volume needs to be created explicitly.

```bash
docker volume create recorder_storage
docker run -d -p 8083:8083 -v recorder_store:/store owntracks/recorder
```

It is also possible to use a local folder instead of an static docker volume.

```bash
mkdir store
docker run -d -p 8083:8083 -v ./store:/store owntracks/recorder
```

If nothing is mounted at `/store`, docker will create a unique volume
automatically. However up on recreation of the docker container, this process
will be repeated and another unique volume will be created. As a result, the
container will have forgotten about previous tracks.

## TLS between MQTT Broker and Recorder

The `OTR_CAPATH` of the container defaults to the `/config` volume. Thus
certificates and key files belong into the `/config` volume. `OTR_CAFILE` must be configured for TLS.

`OTR_CERTFILE` defaults to `cert.pem` and `OTR_KEYFILE` to `key.pem`. These files are optional and the options are ignored if the files don't exist.

## TLS encryption via Reverse Proxy

The Recorder has no encryption module by it self. Instead use a reverse proxy
setup. See https://github.com/jwilder/nginx-proxy for how to do this in a semi
automatic way with docker containers and
https://github.com/owntracks/recorder#reverse-proxy for Recorder specific
details.

## Healthcheck

The Recorder container performs a Docker-style `HEALTHCHECK` on itself by periodically
running `recorder-health.sh` on itself. This program POSTS a `_type: location` JSON
message to itself over HTTP to the ping-ping endpoint and verifies via the HTTP API
whether the message was received.

## Docker compose files

Save a file with the name [docker-compose.yml](docker-compose.yml) and following content.
Run with `docker-compose up` from the same folder.

```yaml
version: '3'

services:

  otrecorder:
    image: owntracks/recorder
    ports:
      - 8083:8083
    volumes:
      - config:/config
      - store:/store
    restart: unless-stopped

volumes:
  store:
  config:
```

This [docker-compose.yml](docker-compose.yml) file creates `store` and `config` volumes. It is
possible to edit the `recorder.conf` file in the `config` volume to get the
system up and running. It is also possible to pass environment variables to the
docker container via the `environment:` keyword. For details see
[here](https://docs.docker.com/compose/environment-variables/) and for available
variables see
[here](https://github.com/owntracks/recorder/blob/master/README.md#configuration-file).

An example might look like:

```yaml
version: '3'

services:

  otrecorder:
    image: owntracks/recorder
    ports:
      - 8083:8083
    volumes:
      - store:/store
    restart: unless-stopped
    environment:
      - OTR_HOST = "mqtt_broker"
      - OTR_USER = "user"
      - OTR_PASS = "pass"

volumes:
  store:
```

### With MQTT broker

If you need to set up an MQTT broker, you can easily use, say, Mosquitto. There are ready to use
containers available on docker hub. To use `eclipse-mosquitto` add something like [the following](docker-compose-mqtt.yml) to your `docker-compose.yml` file.

```yaml
version: '3'

services:

  otrecorder:
    image: owntracks/recorder
    ports:
      - 8083:8083
    volumes:
      - config:/config
      - store:/store
    restart: unless-stopped

  mosquitto:
    image: eclipse-mosquitto
    ports:
      - 1883:1883
      - 8883:8883
    volumes:
      - mosquitto-data:/mosquitto/data
      - mosquitto-logs:/mosquitto/logs
      - mosquitto-conf:/mosquitto/config
    restart: unless-stopped

volumes:
  store:
  config:
  mosquitto-data:
  mosquitto-logs:
  mosquitto-conf:
```

See [here](https://hub.docker.com/_/eclipse-mosquitto) for info on the eclipse-mosquitto image and how to configure it.

### All in one solution with reverse proxy and Let's Encrypt

There are some caveats people seem to step into:

1. mosquitto starts only if the cert files referenced in the configuration are
   accessible. Therefore for a successful retrieval from Let's encrypt by the
   ACME companion those lines in the configuration have to be commented out.
   In order to test things start unencrypted first. 

2. The example documentation to create a password include `-c` as command line
   switch. Be sure only to use this if you **want** to overwrite that password
   file.

3. In order to make ot-recorder talk SSL & accept Let's encrypt certificates a
   kind of concatenated
   [le-ca.pem](https://gist.github.com/jpmens/211dbe7904a0efd40e2e590066582ae5)
   is needed. A [thread](https://github.com/owntracks/recorder/issues/193) in
   an issue is discussing this in detail. In the example below this file is
   downloaded as `ca.pem`. 

4. nginx-proxy allows basic auth. For that one needs to put a file name after
   the virtual host, e.g. `owntrack.domain.com` in the **folder**
   `/etc/nginx/htpasswd`

```yaml

version: '2'

services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy:alpine
    container_name: nginx
    ports:
      - 80:80
      - 443:443
    volumes:
      - ./proxy/conf.d:/etc/nginx/conf.d
      - ./proxy/proxy.conf:/etc/nginx/proxy.conf
      - ./proxy/vhost.d:/etc/nginx/vhost.d
      - ./proxy/html:/usr/share/nginx/html
      - ./proxy/certs:/etc/nginx/certs:ro
      - ./proxy/htpasswd:/etc/nginx/htpasswd:ro
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - acme:/etc/acme.sh
    networks:
      - proxy-tier

  letsencrypt-nginx-proxy-companion:
    image: nginxproxy/acme-companion
    container_name: letsencrypt-companion
    depends_on: [nginx]
    volumes_from:
      - nginx-proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./proxy/certs:/etc/nginx/certs:rw
      - acme:/etc/acme.sh
    #environment:
      #- ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory
      #User above line for testing the setup 

  otrecorder:
    image: owntracks/recorder
    restart: unless-stopped
    environment:
      - VIRTUAL_HOST=owntracks.domain.com
      - VIRTUAL_PORT=8083
      - LETSENCRYPT_HOST=owntracks.domain.com
      - LETSENCRYPT_EMAIL=joe.doe@domain.com
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
      - OTR_USER="user"
      - OTR_PASS="password"
      - OTR_HOST=mqtt.domain.com
      - OTR_PORT=8883
      - OTR_CAFILE=/config/ca.pem
      #content of the file above from https://gist.github.com/jpmens/211dbe7904a0efd40e2e590066582ae5
      #which is 6 certificates in one file. !!!This turns out to be important!!!
    volumes:
      - ./owntracks/config:/config
      - ./owntracks/store:/store
      - ./proxy/certs:/etc/letsencrypt/live:ro #probably this line is not needed
    networks:
      - proxy-tier
  
  mqtt:
    container_name: mqtt
    image: eclipse-mosquitto
    environment:
      - VIRTUAL_HOST=mqtt.domain.com
      - LETSENCRYPT_HOST=mqtt.domain.com
      - LETSENCRYPT_EMAIL=joe.doe@domain.com
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    ports:
      - 1883:1883
      - 8883:8883
      - 8083:8083
    volumes:
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/logs:/mosquitto/logs
      - ./mosquitto/conf:/mosquitto/config
      - ./mosquitto/conf/passwd:/etc/mosquitto/passwd
      - ./proxy/certs:/etc/letsencrypt/live:ro
    restart: unless-stopped

volumes:
  acme:
networks:
  proxy-tier:
    external:
      name: nginx-proxy
```

a minimal mosquitto.conf which can act as a start:

```
allow_anonymous false
password_file /etc/mosquitto/passwd
#use mosquitto_passwd inside container to populate the passwd file

#listener 1883 
#socket_domain ipv4
#uncomment 2 lines above for first run so we get LE certificates. 
#at the same time comment out all lines below. Once you have the certificate
#stop the unencrypted listener

listener 8883
certfile /etc/letsencrypt/live/mqtt.domain.com/cert.pem
cafile /etc/letsencrypt/live/mqtt.domain.com/chain.pem
keyfile /etc/letsencrypt/live/mqtt.domain.com/key.pem

listener 8083
protocol websockets
certfile /etc/letsencrypt/live/mqtt.domain.com/cert.pem
cafile /etc/letsencrypt/live/mqtt.domain.com/chain.pem
keyfile /etc/letsencrypt/live/mqtt.domain.com/key.pem 
```

## Possible enhancements

- Maybe put the most common Mosquitto options in the section which uses an MQTT broker in the docker-compose file

## Credits

- [JSON.lua](http://regex.info/blog/lua/json), by Jeffrey Friedl. [LICENSE](https://creativecommons.org/licenses/by/3.0/)

## Dockerfile for OwnTracks Recorder and Mosquitto

This is a Dockerfile for the [OwnTracks Recorder](https://github.com/owntracks/recorder) which includes the [Mosquitto broker](http://mosquitto.org) as well as the Recorder proper. Documentation for running this is in the [Booklet](http://owntracks.org/booklet/clients/recorder/).

It sets Mosquitto broker (with TLS) as well as the OwnTracks Recorder for collecting [OwnTracks](http://owntracks.org) location data.

Docker images are built automatically when we push Debian packages to the `recorder` repository, and these Docker images are available at [https://hub.docker.com/r/owntracks/recorderd/](https://hub.docker.com/r/owntracks/recorderd/).

#!/bin/sh

# If running as root (first invocation), fix mountpoint permissions
# and re-run this script as appuser.
if [[ $(id -u) -eq 0 ]]; then
  chown -R appuser:appuser /store /config
  exec su -c "$0" appuser
fi

# Load Default recorder.conf if not available
if [ ! -f /config/recorder.conf ]; then
	  cp /etc/default/recorder.conf /config/recorder.conf
fi

ot-recorder --initialize
ot-recorder "$@"

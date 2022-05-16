#!/bin/sh

ADDR=`hostname`
PORT=8083

EPOCH=$(date +%s)

LOCATION=$(cat <<EOJSON
{
  "_type": "location",
  "tid": "pp",
  "lat": 51.47879,
  "lon": -0.010677,
  "tst": ${EPOCH}
}
EOJSON
)

# POST location to ping/ping, ignoring output
curl -sSL --data "${LOCATION}" "http://${ADDR}:${PORT}/pub?u=ping&d=ping" > /dev/null

# obtain tst of ping/ping's last location
RET_EPOCH=$(curl -sSL http://${ADDR}:${PORT}/api/0/last --data "user=ping&device=ping" | env jq -r '.[0].tst' )

if [ ${EPOCH} -ne ${RET_EPOCH} ]; then
       echo PANIC ${EPOCH} ${RET_EPOCH}
       exit 1
else
       echo OK
       exit 0
fi

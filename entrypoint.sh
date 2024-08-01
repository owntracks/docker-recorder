#!/bin/sh

if ! [ -f ${OTR_STORAGEDIR}/ghash/data.mdb ]; then
    ot-recorder --initialize
fi

ot-recorder ${OTR_TOPIC} "$@"

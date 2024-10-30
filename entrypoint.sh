#!/bin/sh

if ! [ -f ${OTR_STORAGEDIR}/ghash/data.mdb ]; then
    ot-recorder --initialize
fi

# invoke ot-recorder with either $OTR_TOPIC or $OTR_TOPICS, with the
# latter overriding the former
ot-recorder ${OTR_TOPICS:-$OTR_TOPIC} "$@"

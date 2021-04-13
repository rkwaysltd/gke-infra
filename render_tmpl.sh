#!/bin/sh
D=$(dirname $0)

if [ -e "${D}/.secrets" ]; then
    . "${D}/.secrets"
fi

: ${PROJECT_ID:?}
: ${TF_STATE_BUCKET:?}

envsubst < "$D/state.tf.tmpl" > "$D/state.tf"

#!/bin/sh

if [ -e ./.secrets ]; then
    . .secrets
fi

: ${PROJECT_ID:?}
: ${TF_STATE_BUCKET:?}
: ${GOOGLE_BACKEND_CREDENTIALS:?}
: ${GOOGLE_APPLICATION_CREDENTIALS:?}
: ${GOOGLE_ENCRYPTION_KEY:?}

envsubst < ./state.tf.tmpl > ./state.tf

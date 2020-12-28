#!/bin/sh

if [ -e ./.secrets ]; then
    . .secrets
fi

: ${PROJECT_ID:?}
: ${TF_STATE_BUCKET:?}

envsubst < ./state.tf.tmpl > ./state.tf
envsubst < ./variables.auto.tfvars.tmpl > ./variables.auto.tfvars

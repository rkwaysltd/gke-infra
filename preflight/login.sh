#!/bin/sh
set -eu

D=$(dirname $0)
OWNER=${1:?run as $0 <owner_email_address>}
GCLOUD_CONFIG=$(gcloud config configurations list --format=json | jq -re '.[] | select(.is_active == true) | .name')

for t in dev prod; do
    PROJECT_ID="$(jq -re .project_id < "$D/../variables.${t}.tfvars.json")"
    gcloud config configurations create gke-infra-${t} || gcloud config configurations activate gke-infra-${t}
    gcloud config set account "$OWNER"
    gcloud config set project "$PROJECT_ID"
    gcloud auth login --no-launch-browser
done

gcloud config configurations activate "$GCLOUD_CONFIG"
echo Done.

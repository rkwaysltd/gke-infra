#!/bin/sh
if [ -e ./.secrets ]; then
    set -a
    . .secrets
    set +a
fi

D=$(dirname $0)
vars="${D}/../variables.dev.tfvars.json"
PROJECT_ID=$(jq -re .project_id < "$vars") "${D}/../render_tmpl.sh"

cmd="${1:?run as: $0 init|plan|apply|...}"
shift

# terraform init should be executed with empty TF_WORKSPACE
if [ "${cmd}" = "init" ]; then
    ws=""
else
    ws="dev"
fi

set -a
TF_WORKSPACE="$ws"
GOOGLE_CREDENTIALS="${GOOGLE_CREDENTIALS_DEV:?}"
TF_VAR_cloudflare_api_token="${CLOUDFLARE_API_TOKEN_DEV:-}"
TF_VAR_letsencrypt_email="${LETSENCRYPT_EMAIL:-}"
TF_VAR_cloudflare_api_email="${CLOUDFLARE_API_EMAIL:-}"
TF_VAR_cloudflare_domain_list="${CLOUDFLARE_DOMAIN_LIST:-}"
set +a
terraform "$cmd" -var-file="$vars" "$@"

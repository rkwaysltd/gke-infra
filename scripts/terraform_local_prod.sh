#!/bin/sh
if [ -e ./.secrets ]; then
    set -a
    . .secrets
    set +a
fi

D=$(dirname $0)
vars="${D}/../variables.prod.tfvars.json"
PROJECT_ID=$(jq -re .project_id < "$vars") "${D}/../render_tmpl.sh"

cmd="${1:?run as: $0 init|plan|apply|...}"
shift

# terraform init should be executed with empty TF_WORKSPACE
if [ "${cmd}" = "init" ]; then
    ws=""
else
    ws="prod"
fi

opts=
case "${cmd}" in
state)
    # no -var-file for state command
    ;;
*)
    opts="-var-file=$vars"
esac

set -a
TF_WORKSPACE="$ws"
GOOGLE_CREDENTIALS="${GOOGLE_CREDENTIALS_PROD:?}"
TF_VAR_cloudflare_api_token="${CLOUDFLARE_API_TOKEN_PROD:-}"
TF_VAR_letsencrypt_email="${LETSENCRYPT_EMAIL:-}"
TF_VAR_cloudflare_api_email="${CLOUDFLARE_API_EMAIL:-}"
TF_VAR_cloudflare_domain_list="${CLOUDFLARE_DOMAIN_LIST:-}"
TF_VAR_cloudflare_domain_ingress_rr="${CLOUDFLARE_DOMAIN_INGRESS_RR:-}"
set +a
terraform "$cmd" $opts "$@"

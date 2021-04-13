#!/bin/sh
D=$(dirname $0)

SECRETS_FILE="${D}/../.secrets"
if [ -e "$SECRETS_FILE" ]; then
    set -a
    . "$SECRETS_FILE"
    set +a
else
    echo >&2 "No .secrets file. This script will fail unless environment variables are already set."
fi

case "$0" in
*terraform_local_dev.sh)
    VARS_FILE="${D}/../variables.dev.tfvars.json"
    TF_WORKSPACE="dev"
    GOOGLE_CREDENTIALS="${GOOGLE_CREDENTIALS_DEV:?}"
    TF_VAR_cloudflare_api_token="${CLOUDFLARE_API_TOKEN_DEV:-}"
    TF_VAR_letsencrypt_email="${LETSENCRYPT_EMAIL:-}"
    TF_VAR_cloudflare_api_email="${CLOUDFLARE_API_EMAIL:-}"
    TF_VAR_cloudflare_domain_list="${CLOUDFLARE_DOMAIN_LIST_DEV:-}"
    TF_VAR_cloudflare_domain_ingress_rr="${CLOUDFLARE_DOMAIN_INGRESS_RR_DEV:-}"
    ;;
*terraform_local_prod.sh)
    VARS_FILE="${D}/../variables.prod.tfvars.json"
    TF_WORKSPACE="prod"
    GOOGLE_CREDENTIALS="${GOOGLE_CREDENTIALS_PROD:?}"
    TF_VAR_cloudflare_api_token="${CLOUDFLARE_API_TOKEN_PROD:-}"
    TF_VAR_letsencrypt_email="${LETSENCRYPT_EMAIL:-}"
    TF_VAR_cloudflare_api_email="${CLOUDFLARE_API_EMAIL:-}"
    TF_VAR_cloudflare_domain_list="${CLOUDFLARE_DOMAIN_LIST_PROD:-}"
    TF_VAR_cloudflare_domain_ingress_rr="${CLOUDFLARE_DOMAIN_INGRESS_RR_PROD:-}"
    ;;
*)
    echo >&2 "Unknown script name, only terraform_local_dev.sh and terraform_local_prod.sh supported."
    exit 1
esac

PROJECT_ID=$(jq -re .project_id < "$VARS_FILE") "${D}/../render_tmpl.sh"

cmd="${1:?run as: $0 init|plan|apply|...}"
shift

# terraform init should be executed with empty TF_WORKSPACE
if [ "${cmd}" = "init" ]; then
    TF_WORKSPACE=""
fi

opts=
case "${cmd}" in
state|force-unlock|providers|version)
    # no -var-file for some command
    ;;
*)
    opts="-var-file=$VARS_FILE"
esac

export \
    TF_WORKSPACE \
    GOOGLE_CREDENTIALS \
    TF_VAR_cloudflare_api_token \
    TF_VAR_letsencrypt_email \
    TF_VAR_cloudflare_api_email \
    TF_VAR_cloudflare_domain_list \
    TF_VAR_cloudflare_domain_ingress_rr
terraform "$cmd" $opts "$@"

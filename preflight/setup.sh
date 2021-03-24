#!/bin/sh
set -eu

D=$(dirname $0)
GCLOUD_CONFIG=$(gcloud config configurations list --format=json | jq -re '.[] | select(.is_active == true) | .name')

# create Terraform service account and key
create_service_account() {
    local project_id="$1"
    local t="$2"

    if  gcloud iam service-accounts list --format=json | \
        jq -re '.[] | select(.displayName == "terraform") | "Service account `terraform` already exists. Skip SA create and keys create actions."'; then
        return
    fi

    gcloud iam service-accounts create terraform \
        --description="Terraform SA" \
        --display-name="terraform"
    gcloud iam service-accounts keys create ./terraform-sa-key-${t}.json \
        --iam-account="terraform@$project_id.iam.gserviceaccount.com"
}

for t in dev prod; do
    vars="$D/../variables.${t}.tfvars.json"

    gcloud config configurations activate gke-infra-${t}
    
    # enable Google Cloud APIs
    gcloud services enable \
        compute.googleapis.com \
        container.googleapis.com \
        cloudresourcemanager.googleapis.com \
        cloudkms.googleapis.com \
        logging.googleapis.com \
        monitoring.googleapis.com

    PROJECT_ID="$(jq -re .project_id < "$vars")"
    create_service_account "${PROJECT_ID}" "${t}"

    # grant necessary permissions
    # https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/v12.3.0#configure-a-service-account
    for role in \
        "roles/compute.viewer" \
        "roles/compute.securityAdmin" \
        "roles/container.admin" \
        "roles/iam.serviceAccountAdmin" \
        "roles/iam.serviceAccountUser" \
        "roles/resourcemanager.projectIamAdmin" \
        "roles/cloudkms.admin" \
        "roles/logging.configWriter"
    do
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
            --role="$role"
    done
done

gcloud config configurations activate "$GCLOUD_CONFIG"

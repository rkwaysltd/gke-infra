#!/bin/sh
set -eu

D=$(dirname $0)
GCLOUD_CONFIG=$(gcloud config configurations list --format=json | jq -re '.[] | select(.is_active == true) | .name')

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

    # create Terraform service account and key
    PROJECT_ID="$(jq -re .project_id < "$vars")"
    gcloud iam service-accounts create terraform \
        --description="Terraform SA" \
        --display-name="terraform"
    gcloud iam service-accounts keys create ./terraform-sa-key-${t}.json \
        --iam-account="terraform@$PROJECT_ID.iam.gserviceaccount.com"

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

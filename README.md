# GKE setup

## Design choices

- Separate project for Terraform state (contains cluster credentials).
- Terraform state bucket located in London without geo-redundancy.
- Two clusters - first for development and second for production deployments.
- _Regular_ [release channel](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels).
- _Zonal_ cluster [location type](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters) while developing infrastructure for cluster.
- _Default_ network/subnet for cluster as the whole project is dedicated for the cluster. Please [see recommendations](https://cloud.google.com/vpc/docs/vpc#default-network).
- __Not private-cluster__. While good for security it adds a huge amount of complexity to cluster infrastructure.
- Google Cloud Storage in the cluster project should __never be used for highly confidential information__. It's primary purpose is to hold the Container Registry and the cluster nodes have read-only access to all buckets. Create GCS bucket for confidential data in separate project.
- Disabled [Config Connector](https://cloud.google.com/config-connector/docs/overview) as preferred way to manage Google Cloud resources is via this Terraform project.
- [Workload identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) enabled as it can be used to control access to Google Cloud services per-Pod Service Account ([Terraform setup example](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/examples/workload_identity)).
- [Compute Engine persistent disk CSI Driver](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver) enabled as it's required for customer-managed encryption keys in `storageclass-cmek` Storage Class.
- Default Storage Class uses `pd-standard` [disk type](https://cloud.google.com/compute/docs/disks).
- [Network Policy](https://cloud.google.com/kubernetes-engine/docs/concepts/network-overview#limit-connectivity-pods) enabled in cluster as a way to secure apps environments from each other.

## Changes to be made before going into production

This settings cannot be changed on existing cluster. Full cluster re-creation required.

- Switch to _Regional_ [location type](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters) to prevent API server outages e.g. during maintenance/upgrades. Please check __Overview__ and __Limitations__ sections in [documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/regional-clusters).

## Encryption settings

- [Application-layer Secrets Encryption](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets)

    Encrypt Kubernetes secrets with `.../keyRings/<cluster_name>/cryptoKeys/k8s-db` KMS key. Automatic rotation every 30 days but [new key versions are only used on freshly created Secrets](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets#re-encrypting_your_secrets).

- Encryption at Rest - [Node root disks](https://cloud.google.com/kubernetes-engine/docs/how-to/using-cmek#boot-disks)

    Node OS/Root disks are encrypted with `.../keyRings/<cluster_name>/cryptoKeys/k8s-root-disk` KMS key. Automatic rotation every 30 days - new key versions are used on freshly created Nodes.

- Encryption at Rest - [Cluster Storage Classes](https://cloud.google.com/kubernetes-engine/docs/how-to/using-cmek#create_an_encrypted_in)

    Persistent Volumes disks created by PVC in any `*-cmek` Storage Class are encrypted with `.../keyRings/<cluster_name>/cryptoKeys/k8s-sc-storageclass-cmek-disk` KMS key. Automatic rotation every 30 days - new key versions are used on freshly created PVs.

- Due to [various speculative execution attacks](https://en.wikipedia.org/wiki/Transient_execution_CPU_vulnerability) it's recommended to use non shared-core [machine type](https://cloud.google.com/compute/docs/machine-types#machine_types) in node pools.

## Minimal hardware requirements

The cluster must have at least 2 nodes of type e2-medium or higher. The recommended minimum size cluster to run network policy enforcement is 3 e2-medium instances.

## Preflight one-time setup

1. Create master project in [Google Cloud console](https://console.cloud.google.com/cloud-resource-manager). Highly confidential Terraform state will be kept in a GCS bucket in that project.

    - create Terraform backend SA

        ```sh
        PROJID="<master project name>"
        gcloud iam service-accounts create tf-backend \
            --project=$PROJID \
            --description="Terraform Backend SA" \
            --display-name="tf-backend"
        gcloud iam service-accounts keys create ./tf-backend-sa-key.json \
            --iam-account="tf-backend@${PROJID}.iam.gserviceaccount.com"
        ```

    - copy content of `./tf-backend-sa-key.json` file content into `GOOGLE_BACKEND_CREDENTIALS` GitHub project secret

    - create bucket and grant permissions

        ```sh
        # Bucket name is global - pick a unique one
        TF_STATE_BUCKET="<bucket name>"
        PROJID="<master project name>"
        gsutil mb -b on -p $PROJID -c standard -l europe-west2 gs://$TF_STATE_BUCKET/
        # Backup old versions
        gsutil versioning set on gs://$TF_STATE_BUCKET/
        gsutil iam ch \
            serviceAccount:tf-backend@${PROJID}.iam.gserviceaccount.com:roles/storage.legacyBucketWriter \
            gs://$TF_STATE_BUCKET/
        gsutil iam ch \
            serviceAccount:tf-backend@${PROJID}.iam.gserviceaccount.com:roles/storage.objectViewer \
            gs://$TF_STATE_BUCKET/
        ```

    - copy `TF_STATE_BUCKET` into GigHub project secret (same name)

    - generate bucket encryption key

        ```sh
        openssl rand -base64 32
        ```

    - copy generated key into `GOOGLE_ENCRYPTION_KEY` GitHub secret

1. Create two projects in [Google Cloud console](https://console.cloud.google.com/cloud-resource-manager).

    - edit Terraform variables in `variables.dev.tfvars.json` and `variables.prod.tfvars.json` files:

        - Google Cloud project names in the `project_id` field
        - Kubernetes cluster names in the `name` field

    - run login script with your Google Cloud project owner account id as argument, copy displayed links into browser and follow instructions:

        ```bash
        ./preflight/login.sh owner.email.account@gmail.com
        ```

    - run `./preflight/setup.sh` script

    - copy content of `./terraform-sa-key-dev.json` file into `GOOGLE_CREDENTIALS_DEV` GitHub project secret

    - copy content of `./terraform-sa-key-prod.json` file into `GOOGLE_CREDENTIALS_PROD` GitHub project secret

## Scratchpad.

    ```sh
    gcloud container clusters list
    gcloud container clusters get-credentials gke-cluster
    ```

## Local machine usage

Issuing commands from local machine should only be considered in the cluster development stage and never to production cluster.

- update `./secrets` file based on `./secrets.example`
- run `set -a; . .secrets; set +a` to set shell variables
- run `PROJECT_ID=dev ./render_tmpl.sh` script
- run `TF_WORKSPACE=dev terraform init`

It should be possible to e.g. see output from `TF_WORKSPACE=dev terraform plan -var-file=./variables.dev.tfvars.json` command.

## Local machine (gcloud) cleanup

```sh
gcloud config configurations activate default
gcloud config configurations delete gke-infra-dev
gcloud config configurations delete gke-infra-prod
```

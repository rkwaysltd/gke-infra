# GKE setup

## Design choices

### Project

- Two clusters - first for development and second for production deployments.

### Terraform

- Separate project for Terraform state (contains cluster credentials).
- Terraform state bucket located in London without geo-redundancy.
- Terraform `plan` stored as comment on PR issues.
- Terraform execute `apply` command on push to `main` and `main-prod` branches.

### GKE

- _Regular_ [release channel](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels).
- _Multi zonal_ clusters not supported. Production cluster should have redundant control plane, development cluster can live in single zone.
- _Default_ network/subnet for cluster as the whole project is dedicated for the cluster. Please [see recommendations](https://cloud.google.com/vpc/docs/vpc#default-network).
- __Not private-cluster__. While good for security it adds a huge amount of complexity to cluster infrastructure.
- Google Cloud Storage in the cluster project should __never be used for highly confidential information__. It's primary purpose is to hold the Container Registry and the cluster nodes have read-only access to all buckets. Create GCS bucket for confidential data in separate project.
- Disabled [Config Connector](https://cloud.google.com/config-connector/docs/overview) as preferred way to manage Google Cloud resources is via this Terraform project.
- [Workload identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) enabled as it can be used to control access to Google Cloud services per-Pod Service Account ([Terraform setup example](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/examples/workload_identity)).
- [Compute Engine persistent disk CSI Driver](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver) enabled as it's required for customer-managed encryption keys in `storageclass-cmek` Storage Class.
- Default Storage Class uses `pd-standard` [disk type](https://cloud.google.com/compute/docs/disks).
- [Network Policy](https://cloud.google.com/kubernetes-engine/docs/concepts/network-overview#limit-connectivity-pods) enabled in cluster as a way to secure apps environments from each other.

### Ingress Networking

- [Container-native load balancing](https://cloud.google.com/kubernetes-engine/docs/concepts/container-native-load-balancing) is much better than other options.

    Preferred flow route: Client -> GCP load-balancer with global IP address -> Nginx Ingress Controller Pods via [NEG](https://cloud.google.com/load-balancing/docs/negs) -> App Pods directly via [Endpoints](https://v1-18.docs.kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#endpoints-v1-core).

- GKE Ingress Controller enabled but not used in this setup.

    It's [a requirement](https://cloud.google.com/kubernetes-engine/docs/concepts/container-native-load-balancing#requirements) of the container-native load-balancing. Any [Ingress](https://v1-18.docs.kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#ingress-v1beta1-networking-k8s-io) object with `""` (empty string) or `"gce"` in `kubernetes.io/ingress.class` annotation will be handled by GKE Ingress Controller.

- The [Ingress](https://v1-18.docs.kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#ingress-v1beta1-networking-k8s-io) resources needs `kubernetes.io/ingress.class` annotation with `ngx` string.

    Example:

    ```yaml
    metadata:
      name: foo
      annotations:
        kubernetes.io/ingress.class: "ngx"
    ```

- While it's possible to set `PREMIUM` or `STANDARD` Network Tier changes on existing cluster needs to be carefully considered as the entry IP address is going to change.

- Ingress IP address will be placed in DNS as `<ingress_rr_name>.<configured_domain_name>`, other domain names can use `CNAME` records to point to it.

- Ingress object with Let's Encrypt generated certificate example:

    ```yaml
    apiVersion: networking.k8s.io/v1beta1
    kind: Ingress
    metadata:
      annotations:
        kubernetes.io/ingress.class: "ngx"
        cert-manager.io/cluster-issuer: letsencrypt-issuer
      name: example-ingress
      namespace: example-ingress-ns
    spec:
      rules:
      - host: test.example.com
        http:
          paths:
          - backend:
              serviceName: example-svc
              servicePort: 8080
            path: /
      tls:
      - hosts:
        - test.example.com
        secretName: test-example-com
    ```

### Logging

The GKE cluster is configured to use [Cloud Logging](https://cloud.google.com/logging).

The [Cert Manager](https://cert-manager.io/) and [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/) logs are sent to pre-configured buckets from all the Pods in that Kubernetes Namespace.

Applications deployed to cluster can use Pod labels to pick proper log retention bucket. See shortened example below or [full example](./examples/logging.yaml). Please remember that label value on the right side should be a string - enclosing it in `""` characters is very much needed. Values other than specified in `logs_retention_bylabel_buckets` Terraform variable are silently ignored.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  ...
spec:
  ...
  template:
    metadata:
      labels:
        ...
        rkways.com/gke-infra-logdays: "7"
      ...
```

All logs not covered by above rules will go into the default bucket.

The [Cloud Logging](https://cloud.google.com/logging) subsystem currently don't support Customer Managed Encryption Keys for stored logs. If that's a requirement there is a way to send logs via CMEK-enabled [Cloud Logging Router](https://cloud.google.com/logging/docs/routing/managed-encryption) into [a destination that supports CMEK](https://cloud.google.com/logging/docs/routing/managed-encryption#exports).

## Changes to be made before going into production

This settings cannot be changed on existing cluster. Full cluster re-creation required.

- Switch to _Regional_ [location type](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters) to prevent API server outages e.g. during maintenance/upgrades. Please check __Overview__ and __Limitations__ sections in [documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/regional-clusters). Single entry in `zones` Terraform variable means [_Zonal_ cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters), add more zones to switch to [_Regional_ cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters).

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

1. Fork this project on GitHub, set branch `main-prod` as protected.

1. Make sure that the variable `terraform_preflight` is set to `true` in `variables.dev.tfvars.json` and `variables.prod.tfvars.json`.

1. Create master project in [Google Cloud console](https://console.cloud.google.com/cloud-resource-manager). Highly confidential Terraform state will be kept in a GCS bucket in that project.

    - add gcloud `gke-infra-master` configuration (please change `owner.email.account@gmail.com` to correct address)

        ```
        PROJID="<master project name>"
        gcloud config configurations create gke-infra-master
        gcloud config set account owner.email.account@gmail.com
        gcloud config set project "$PROJID"
        gcloud auth login --activate --no-launch-browser
        ```

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

    - run login script with _your Google Cloud project owner account id as argument_, copy displayed links into browser and follow instructions:

        ```bash
        ./preflight/login.sh owner.email.account@gmail.com
        ```

    - run `./preflight/setup.sh` script

    - copy content of `./terraform-sa-key-dev.json` file into `GOOGLE_CREDENTIALS_DEV` GitHub project secret

    - copy content of `./terraform-sa-key-prod.json` file into `GOOGLE_CREDENTIALS_PROD` GitHub project secret

1. Configure [cert-manager](https://cert-manager.io/) for managing TLS certificates via Cloudflare DNS01 Challenge Provider

    - API tokens should be created via [Cloudflare dashboard](https://dash.cloudflare.com/profile/api-tokens) Create Custom Token action

    - permissions for API tokens:

        - Zone.Zone:Read (three pull-down buttons: Zone, DNS, Edit)
        - Zone.DNS:Edit (`+ Add more`, then choose Zone, Zone, Read)

    - it's good idea to pick specific domains in the `Zone Resources` section (separate for dev and prod clusters)

    - create dev API token for development cluster domains and put the token in the `CLOUDFLARE_API_TOKEN_DEV` GitHub project secret

    - create prod API token for production cluster domains and put the token in the `CLOUDFLARE_API_TOKEN_PROD` GitHub project secret

    - rest of the configuration should be put into the GitHub project secrets or directly in the Terraform input variables files `variables.dev.tfvars.json` and `variables.prod.tfvars.json`

        | GitHub secret | Terraform variable | Description |
        |---------------|--------------------|-------------|
        | `LETSENCRYPT_EMAIL` | `letsencrypt_email` | [Let's Encrypt](https://letsencrypt.org/) notifications email |
        | `CLOUDFLARE_API_EMAIL` | `cloudflare_api_email` | Cloudflare account email |
        | `CLOUDFLARE_DOMAIN_LIST_DEV` | `cloudflare_domain_list` | Comma separated list of domains managed by Cloudflare token (development domains) |
        | `CLOUDFLARE_DOMAIN_LIST_PROD` | `cloudflare_domain_list` | Comma separated list of domains managed by Cloudflare token (production domains) |
        | `CLOUDFLARE_DOMAIN_INGRESS_RR_DEV` | `cloudflare_domain_ingress_rr` | Domain with A-type DNS resource record, one from the above list (development) |
        | `CLOUDFLARE_DOMAIN_INGRESS_RR_PROD` | `cloudflare_domain_ingress_rr` | Domain with A-type DNS resource record, one from the above list (production) |

1. Do a `git push` to the `main` branch of your project. That should create GKE cluster with some resources in it (and install all the CRDs in Kubernetes).

1. Set `terraform_preflight` to false in `variables.dev.tfvars.json` and do another git push. That should create rest of the resources.

1. Git push to the `main-prod` branch.

1. Set `terraform_preflight` to false in `variables.prod.tfvars.json` and again a `git push`.

## More configuration variables

### Logging

    | Terraform variable | Description | Default Value |
    |--------------------|-------------|---------------|
    | `logs_retention_days` | Default logs retention [days] | 14 |
    | `logs_retention_days_cert_manager` | Logs retention for Pods in `cert-manager` namespace [days] | 30 |
    | `logs_retention_days_nginx_ingress` | Logs retention for Pods in `nginx-ingress` namespace [days] | 30 |
    | `logs_retention_bylabel_buckets` | Comma separated list of numbers configuring per Pod-label logs retention [days] | 7,14,30,60,90 |

## Issues

In some cases like e.g. replacing default node pool in cluster the provider configuration from `cluster-core` module might not be properly propagated into `cluster-mid` and `cluster-late` modules. The problem manifests itself by e.g. kubernetes provider trying to reach our cluster on `localhost` URLs. In such cases please try to push a commit with `cluster-core` string in `terraform_target` file.

```bash
echo "cluster-core" > terraform_target
git commit terraform_target -m "Only cluster-core module for now"
git push
```

After applying the changes (PR merge) try to remove file content in another PR - carefully check the generated plan for any unexpected changes.

## Local machine `kubectl`

After creation of a cluster:

```sh
gcloud container clusters list
# for zonal clusters
gcloud container clusters get-credentials CLUSTER_NAME --zone CLUSTER_ZONE
# or for regional clusters
gcloud container clusters get-credentials CLUSTER_NAME --region CLUSTER_REGION
```

## Local machine `terraform`

Issuing commands from local machine should only be considered in the cluster development stage and never to production cluster.

- update `./.secrets` file based on `./.secrets.example`
- run `./scripts/terraform_local_dev.sh init`
- run `./scripts/terraform_local_dev.sh plan` and possibly `./scripts/terraform_local_dev.sh apply`

## Local machine (gcloud) cleanup

```sh
gcloud config configurations activate default
gcloud config configurations delete gke-infra-master
gcloud config configurations delete gke-infra-dev
gcloud config configurations delete gke-infra-prod
```

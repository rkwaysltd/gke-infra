module "gke" {
  source                     = "github.com/rkwaysltd/terraform-google-kubernetes-engine?ref=gke-infra/modules/beta-public-cluster"
  project_id                 = var.project_id
  regional                   = (length(var.zones) > 1) ? true : false
  region                     = var.region
  zones                      = var.zones
  name                       = var.name
  release_channel            = "REGULAR"
  gce_pd_csi_driver          = true
  network                    = "default"
  subnetwork                 = "default"
  ip_range_pods              = ""
  ip_range_services          = ""
  http_load_balancing        = true
  horizontal_pod_autoscaling = false
  network_policy             = true
  grant_registry_access      = true

  database_encryption = [{
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.db.self_link
  }]

  maintenance_start_time = "1970-01-01T02:00:00Z"
  maintenance_end_time   = "1970-01-01T08:00:00Z"
  maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SU,SA;INTERVAL=1"

  remove_default_node_pool = true

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = var.machine_type
      min_count          = var.min_count
      max_count          = var.max_count
      disk_size_gb       = var.disk_size_gb
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = true
      initial_node_count = var.initial_node_count
      boot_disk_kms_key  = google_kms_crypto_key.root_disk.self_link
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      # See https://cloud.google.com/compute/docs/access/service-accounts and https://github.com/rkwaysltd/gke-infra/issues/14
      #
      # "The best practice is for you to set the full cloud-platform access scope
      # on the instance, then securely limit your service account's access by
      # granting IAM roles to the service account."
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    # Nginx Ingress controller Pods are not limited to any particular node
    all = ["load-balanced-backend"]

    default-node-pool = [
      "default-node-pool",
    ]
  }

  # Explicit dependency on KMS key permissions
  depends_on = [
    google_kms_crypto_key_iam_binding.crypto_key_db,
    google_kms_crypto_key_iam_binding.crypto_key_root_disk,
  ]
}

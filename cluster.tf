module "gke" {
  source     = "github.com/rkwaysltd/terraform-google-kubernetes-engine?ref=gke-infra/modules/beta-public-cluster"
  project_id = var.project_id
  # for development phase
  regional = false
  region   = "europe-west2"
  zones    = ["europe-west2-b"]
  # for production phase
  #region                     = var.region
  #zones                      = var.zones
  name                       = var.name
  release_channel            = "REGULAR"
  network                    = "default"
  subnetwork                 = "default"
  ip_range_pods              = ""
  ip_range_services          = ""
  http_load_balancing        = false
  horizontal_pod_autoscaling = false
  network_policy             = false
  grant_registry_access      = true

  database_encryption = [{
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.db.self_link
  }]

  maintenance_start_time = "1970-01-01T02:00:00Z"
  maintenance_end_time = "1970-01-01T08:00:00Z"
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
      image_type         = "cos_containerd"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      initial_node_count = var.initial_node_count
      boot_disk_kms_key  = google_kms_crypto_key.root_disk.self_link
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
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
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}

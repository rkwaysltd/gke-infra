module "gcloud_no_default_standard_storageclass" {
  source           = "terraform-google-modules/gcloud/google//modules/kubectl-wrapper"
  version          = "~> 2.0.2"
  upgrade          = false
  project_id       = var.project_id
  cluster_name     = module.gke.name
  cluster_location = module.gke.location

  kubectl_create_command  = "kubectl annotate storageclass standard storageclass.kubernetes.io/is-default-class-"
  kubectl_destroy_command = "kubectl annotate storageclass standard storageclass.kubernetes.io/is-default-class=true"

  module_depends_on = concat(
    [data.google_client_config.default.access_token],
    [module.gke.master_version],
  )
}

resource "kubernetes_storage_class" "standard_cmek" {
  metadata {
    name = "standard-cmek"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = true
    }
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type                      = "pd-standard"
    "disk-encryption-kms-key" = google_kms_crypto_key.sc_standard_cmek_disk.self_link
  }

  depends_on = [
    module.gcloud_no_default_standard_storageclass.wait
  ]
}

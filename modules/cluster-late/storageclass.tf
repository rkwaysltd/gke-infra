module "gcloud_no_default_standard_storageclass" {
  source           = "terraform-google-modules/gcloud/google//modules/kubectl-wrapper"
  version          = "~> 2.0.2"
  upgrade          = false
  project_id       = var.project_id
  cluster_name     = var.name
  cluster_location = var.location

  kubectl_create_command  = "kubectl annotate storageclass standard storageclass.kubernetes.io/is-default-class-"
  kubectl_destroy_command = "kubectl annotate storageclass standard storageclass.kubernetes.io/is-default-class=true"
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
    "disk-encryption-kms-key" = var.disk_encryption_key
  }

  depends_on = [
    module.gcloud_no_default_standard_storageclass.wait,
  ]
}

resource "kubernetes_storage_class" "premium_rwo_cmek" {
  metadata {
    name = "premium-rwo-cmek"
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type                      = "pd-ssd"
    "disk-encryption-kms-key" = var.disk_encryption_key
  }
}

resource "kubernetes_storage_class" "standard_rwo_cmek" {
  metadata {
    name = "standard-rwo-cmek"
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type                      = "pd-balanced"
    "disk-encryption-kms-key" = var.disk_encryption_key
  }
}

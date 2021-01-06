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

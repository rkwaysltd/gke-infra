resource "google_compute_global_address" "nginx_ingress_ip" {
  name = "nginx-ingress-ip"

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    annotations = {
      name = "nginx-ingress"
    }

    labels = {
      name = "nginx-ingress"
    }

    name = "nginx-ingress"
  }
}

data "template_file" "nginx_ingress_helm_chart" {
  template = file("${path.module}/chart-values/nginx-ingress-values.yaml.tmpl")

  vars = {
    project_id = var.project_id
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.24.0"
  namespace  = kubernetes_namespace.nginx_ingress.metadata[0].name
  skip_crds  = false

  values = [
    data.template_file.nginx_ingress_helm_chart.rendered
  ]

}

data "google_compute_network_endpoint_group" "nginx_ingress_80" {
  for_each = toset(module.gke.zones)

  name = "${var.project_id}-nginx-ingress-80"
  zone = each.value
}

data "google_compute_network_endpoint_group" "nginx_ingress_443" {
  for_each = toset(module.gke.zones)

  name = "${var.project_id}-nginx-ingress-443"
  zone = each.value
}

resource "google_compute_health_check" "nginx_ingress_443_health_check" {
  name        = "nginx-ingress-443-health-check"
  description = "Health check via GET https://healthz"

  # 5/5/2/2 are defaults from https://console.cloud.google.com/compute/healthChecksAdd
  #timeout_sec         = 5
  #check_interval_sec  = 5
  #healthy_threshold   = 2
  #unhealthy_threshold = 2

  https_health_check {
    port_specification = "USE_SERVING_PORT"
    request_path       = "/healthz"
    #FIXME: turn on later - proxy_header       = "PROXY_V1"
  }
}

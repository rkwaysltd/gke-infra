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

data "google_compute_network_endpoint_group" "ingress_nginx_80" {
  for_each = toset(module.gke.zones)

  name = "${var.project_id}-ingress-nginx-80"
  zone = each.value
}

data "google_compute_network_endpoint_group" "ingress_nginx_443" {
  for_each = toset(module.gke.zones)

  name = "${var.project_id}-ingress-nginx-443"
  zone = each.value
}

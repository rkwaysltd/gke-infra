resource "google_compute_global_address" "nginx_ingress_ip" {
  # only for PREMIUM network tier
  count = (var.load_balancing_network_tier == "PREMIUM") ? 1 : 0

  name = "nginx-ingress-ip"

  lifecycle {
    # change this to false if you need to switch network tier
    prevent_destroy = true
  }
}

resource "google_compute_address" "nginx_ingress_ip" {
  # only for STANDARD network tier
  count = (var.load_balancing_network_tier == "STANDARD") ? 1 : 0

  name         = "nginx-ingress-ip"
  network_tier = var.load_balancing_network_tier

  lifecycle {
    # change this to false if you need to switch network tier
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

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.24.0"
  namespace  = kubernetes_namespace.nginx_ingress.metadata[0].name
  skip_crds  = false

  values = [
    templatefile(
      "${path.module}/chart-values/nginx-ingress-values.yaml.tmpl",
      {
        project_id     = var.project_id
        gfe_proxy_cird = var.load_balancing_gfe_proxy_cidr
      }
    )
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
    proxy_header       = "PROXY_V1"
  }
}

resource "google_compute_firewall" "nginx_ingress_health_check" {
  name      = "nginx-ingress-health-check"
  network   = data.google_compute_network.default.id
  direction = "INGRESS"

  source_ranges = var.load_balancing_health_check_cidr
  target_tags   = ["load-balanced-backend"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_backend_service" "nginx_ingress_443" {
  name          = "nginx-ingress-443"
  protocol      = "TCP"
  health_checks = [google_compute_health_check.nginx_ingress_443_health_check.id]

  dynamic "backend" {
    for_each = toset(module.gke.zones)

    content {
      group                        = data.google_compute_network_endpoint_group.nginx_ingress_443[backend.value].self_link
      balancing_mode               = "CONNECTION"
      max_connections_per_endpoint = var.load_balancing_max_connections_per_endpoint
    }
  }
}

resource "google_compute_target_tcp_proxy" "nginx_ingress_443" {
  name            = "nginx-ingress-443"
  backend_service = google_compute_backend_service.nginx_ingress_443.id
  proxy_header    = "PROXY_V1"
}

resource "google_compute_global_forwarding_rule" "nginx_ingress_443" {
  # only for PREMIUM network tier
  count = (var.load_balancing_network_tier == "PREMIUM") ? 1 : 0

  name        = "nginx-ingress-443"
  ip_address  = google_compute_global_address.nginx_ingress_ip[0].address
  ip_protocol = "TCP"
  port_range  = "443"
  target      = google_compute_target_tcp_proxy.nginx_ingress_443.self_link
}

resource "google_compute_forwarding_rule" "nginx_ingress_443" {
  # only for STANDARD network tier
  count = (var.load_balancing_network_tier == "STANDARD") ? 1 : 0

  name         = "nginx-ingress-443"
  ip_address   = google_compute_address.nginx_ingress_ip[0].address
  ip_protocol  = "TCP"
  port_range   = "443"
  network_tier = var.load_balancing_network_tier
  target       = google_compute_target_tcp_proxy.nginx_ingress_443.self_link
}

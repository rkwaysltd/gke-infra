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
        project_id               = var.project_id
        gfe_proxy_cird           = var.load_balancing_gfe_proxy_cidr
        controller_namespace     = kubernetes_namespace.nginx_ingress.metadata[0].name
        default_certificate_name = "nginx-ingress-certificate"
      }
    )
  ]
}

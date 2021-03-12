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
    file("chart-values/nginx-ingress-values.yaml")
  ]
}

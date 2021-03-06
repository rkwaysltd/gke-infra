resource "kubernetes_namespace" "cert_manager" {
  metadata {
    annotations = {
      name = "cert-manager"
    }

    labels = {
      name = "cert-manager"
    }

    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.1.0"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  skip_crds  = false

  set {
    name  = "installCRDs"
    value = "true"
  }

  values = [
    file("${path.module}/chart-values/certman-values.yaml")
  ]
}

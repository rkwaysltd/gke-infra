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

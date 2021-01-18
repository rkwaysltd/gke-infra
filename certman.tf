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

  set {
    name  = "resources"
    value = <<EOF
{
  limits: {
    memory: '256Mi',
    cpu: '200m',
  },
  requests: {
    memory: '128Mi',
    cpu: '100m',
  },
}
EOF
  }

  set {
    name  = "webhook.resources"
    value = <<EOF
{
  limits: {
    memory: '128Mi',
    cpu: '200m',
  },
  requests: {
    memory: '64Mi',
    cpu: '100m',
  },
}
EOF
  }

  set {
    name  = "cainjector.resources"
    value = <<EOF
{
  limits: {
    memory: '128Mi',
    cpu: '200m',
  },
  requests: {
    memory: '64Mi',
    cpu: '100m',
  },
}
EOF
  }
}

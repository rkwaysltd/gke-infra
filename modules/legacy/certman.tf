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

resource "kubernetes_secret" "cert_manager_cf" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
  }

  data = {
    api-token = var.cloudflare_api_token
  }

  count = (var.cloudflare_api_token == "" ? 0 : 1)
}

resource "kubernetes_manifest" "cert_manager_cf_issuer" {
  provider = kubernetes-alpha

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-issuer"
    }
    spec = {
      acme = {
        email = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-issuer-account-key"
        }
        server = "https://acme-v02.api.letsencrypt.org/directory"
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  key  = "api-token"
                  name = kubernetes_secret.cert_manager_cf[0].metadata[0].name
                }
                email = var.cloudflare_api_email
              }
            }
            selector = {
              dnsZones = [
                for domain in split(",", var.cloudflare_domain_list) :
                trimspace(domain)
              ]
            }
          }
        ]
      }
    }
  }

  count = (var.cloudflare_api_email == "" || var.letsencrypt_email == "" || var.cloudflare_domain_list == "" ? 0 : 1)
}

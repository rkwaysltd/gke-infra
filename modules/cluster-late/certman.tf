resource "kubernetes_secret" "cert_manager_cf" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = var.cert_manager_namespace
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
              dnsZones = local.cloudflare_domain_list
            }
          }
        ]
      }
    }
  }

  count      = (var.cloudflare_api_email == "" || var.letsencrypt_email == "" || var.cloudflare_domain_list == "" ? 0 : 1)
}

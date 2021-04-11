output "cert_manager_namespace" {
  description = "Certificate Manager namespace."
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "nginx_ingress_namespace" {
  description = "Nginx Ingress Controller namespace."
  value       = kubernetes_namespace.nginx_ingress.metadata[0].name
}

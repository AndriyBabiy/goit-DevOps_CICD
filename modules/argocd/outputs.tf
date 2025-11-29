output "namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "release_name" {
  description = "ArgoCD Helm release name"
  value       = helm_release.argocd.name
}

output "server_service_name" {
  description = "ArgoCD server service name"
  # ArgoCD Helm chart uses "argocd-server" (not "{release-name}-argocd-server")
  value       = "argocd-server"
}

output "get_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"
}

output "port_forward_command" {
  description = "Command to port-forward ArgoCD server"
  # Use port 80 (HTTP) since server_insecure=true, and 8081 locally (8080 used by Jenkins)
  value       = "kubectl port-forward svc/argocd-server -n ${kubernetes_namespace.argocd.metadata[0].name} 8081:80"
}

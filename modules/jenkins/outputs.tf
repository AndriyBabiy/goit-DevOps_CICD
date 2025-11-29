output "namespace" {
  description = "Jenkins namespace"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "release_name" {
  description = "Jenkins Helm release name"
  value       = helm_release.jenkins.name
}

output "service_name" {
  description = "Jenkins service name"
  # Chart 5.x uses release name directly (not {release-name}-jenkins)
  value       = helm_release.jenkins.name
}

output "admin_user" {
  description = "Jenkins admin username"
  value       = var.admin_user
}

output "get_admin_password_command" {
  description = "Command to get Jenkins admin password"
  # Chart 5.x stores password in secret named after release
  value       = "kubectl get secret ${helm_release.jenkins.name} -n ${kubernetes_namespace.jenkins.metadata[0].name} -o jsonpath='{.data.jenkins-admin-password}' | base64 -d && echo"
}

output "port_forward_command" {
  description = "Command to port-forward Jenkins"
  value       = "kubectl --namespace ${kubernetes_namespace.jenkins.metadata[0].name} port-forward svc/${helm_release.jenkins.name} 8080:8080"
}

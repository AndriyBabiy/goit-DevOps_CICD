variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.0"  # Check for latest stable version
}

variable "server_service_type" {
  description = "Service type for ArgoCD server"
  type        = string
  default     = "LoadBalancer"  # Use ClusterIP + port-forward for cost savings
}

variable "server_insecure" {
  description = "Disable TLS on ArgoCD server"
  type        = bool
  default     = true  # For demo purposes; enable TLS in production
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

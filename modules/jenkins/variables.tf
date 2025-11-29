variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "jenkins"
}

variable "chart_version" {
  description = "Jenkins Helm chart version"
  type        = string
  default     = "5.8.3"  # Jenkins LTS 2.479.1 (Nov 2024)
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "LoadBalancer"  # Use ClusterIP + port-forward for cost savings
}

variable "admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "storage_class" {
  description = "Storage class for Jenkins PVC"
  type        = string
  default     = "gp2"
}

variable "storage_size" {
  description = "Storage size for Jenkins PVC"
  type        = string
  default     = "8Gi"
}

variable "controller_resources" {
  description = "Resource limits for Jenkins controller"
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  default = {
    requests_cpu    = "250m"
    requests_memory = "256Mi"
    limits_cpu      = "500m"
    limits_memory   = "512Mi"
  }
}

variable "install_plugins" {
  description = "List of Jenkins plugins to install"
  type        = list(string)
  # Use plugin names without versions - Jenkins will resolve compatible versions
  default = [
    "kubernetes",
    "workflow-aggregator",
    "git",
    "configuration-as-code"
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

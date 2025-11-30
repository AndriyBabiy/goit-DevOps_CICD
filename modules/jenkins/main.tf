# Create namespace for Jenkins
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Create service account for Jenkins
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

# Create cluster role binding for Jenkins to manage pods
resource "kubernetes_cluster_role_binding" "jenkins" {
  metadata {
    name = "jenkins-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"  # Note: In production, use more restrictive role
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins.metadata[0].name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

# Deploy Jenkins using Helm
resource "helm_release" "jenkins" {
  name       = var.release_name
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version
  timeout = 600
  wait    = false  # Don't wait - Terraform completes immediately, diagnose Jenkins manually

  values = [
    yamlencode({
      controller = {
        # Jenkins 5.x chart uses nested admin object
        admin = {
          username = var.admin_user
        }

        serviceType = var.service_type

        resources = {
          requests = {
            cpu    = var.controller_resources.requests_cpu
            memory = var.controller_resources.requests_memory
          }
          limits = {
            cpu    = var.controller_resources.limits_cpu
            memory = var.controller_resources.limits_memory
          }
        }

        installPlugins = var.install_plugins

        # JCasC (Jenkins Configuration as Code) settings
        JCasC = {
          defaultConfig = true
        }

        # Startup probe - allow more time for Jenkins to initialize on small instances
        startupProbe = {
          httpGet = {
            path = "/login"
            port = "http"
          }
          initialDelaySeconds = 120    # Wait 2 min before first check
          periodSeconds       = 15     # Check every 15 seconds
          timeoutSeconds      = 5
          failureThreshold    = 30     # Allow 30 failures (~7.5 min window)
        }

        # Init container needs more memory for plugin downloads
        initContainerResources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1024Mi"
          }
        }
      }

      persistence = {
        enabled = false  # Disabled - EBS CSI driver not installed on EKS
      }

      serviceAccount = {
        create = false
        name   = kubernetes_service_account.jenkins.metadata[0].name
      }

      rbac = {
        create = false
      }
    })
  ]

  depends_on = [
    kubernetes_cluster_role_binding.jenkins
  ]
}

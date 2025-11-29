# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Deploy ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = var.release_name
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  values = [
    yamlencode({
      global = {
        # Add any global settings here
      }

      server = {
        service = {
          type = var.server_service_type
        }

        extraArgs = var.server_insecure ? ["--insecure"] : []

        # Resource limits (reduced for t3.micro)
        resources = {
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }

      controller = {
        resources = {
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }

      repoServer = {
        resources = {
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }

      redis = {
        resources = {
          limits = {
            cpu    = "100m"
            memory = "128Mi"
          }
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
        }
      }

      dex = {
        enabled = false  # Disable dex for simpler setup
      }

      applicationSet = {
        enabled = false  # Disable for simpler setup
      }

      notifications = {
        enabled = false  # Disable for simpler setup
      }
    })
  ]
}

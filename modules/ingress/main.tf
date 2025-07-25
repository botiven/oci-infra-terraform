resource "random_password" "tunnel_secret" {
  length  = 64
  special = true
}

resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress"
  }
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = kubernetes_namespace.ingress.metadata[0].name

  values = [
    yamlencode({
      deployment = {
        replicas = 1
      }
      rbac = {
        enabled = true
      }
      ingressRoute = {
        dashboard = {
          enabled = false
        }
      }
      dashboard = {
        enabled = true
      }
      metrics = {
        prometheus = {
          enabled = true
        }
      }
      ports = {
        web = {
          port = 8000
        }
        websecure = {
          port = 8443
        }
      }
      commonLabels = {
        app = "traefik"
      }
      service = {
        enabled = true
        type    = "ClusterIP"
      }
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    })
  ]
}

resource "kubernetes_manifest" "traefik_dashboard_ingressroute" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "traefik-dashboard"
      namespace = kubernetes_namespace.ingress.metadata[0].name
    }
    spec = {
      entryPoints = ["web", "websecure"]
      routes = [
        {
          match = "Host(`traefik.${var.ingress_domain}`)"
          kind  = "Rule"
          services = [
            {
              name = "api@internal"
              kind = "TraefikService"
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.traefik]
}

resource "kubernetes_manifest" "traefik_hpa" {
  manifest = {
    apiVersion = "autoscaling/v2"
    kind       = "HorizontalPodAutoscaler"
    metadata = {
      name      = "traefik-hpa"
      namespace = kubernetes_namespace.ingress.metadata[0].name
    }
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = "traefik"
      }
      minReplicas = 1
      maxReplicas = 5
      metrics = [
        {
          type = "Resource"
          resource = {
            name = "cpu"
            target = {
              type               = "Utilization"
              averageUtilization = 70
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.traefik]
}

resource "kubernetes_secret" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = kubernetes_namespace.ingress.metadata[0].name
  }

  data = {
    cloudflare_api_token = var.cloudflare_api_token
  }

  type = "Opaque"
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.cloudflare_account_id
  name       = "K8S Ingress"
  secret     = base64encode(random_password.tunnel_secret.result)
}

resource "kubernetes_secret" "tunnel" {
  metadata {
    name      = "tunnel-credentials"
    namespace = kubernetes_namespace.ingress.metadata[0].name
  }

  data = {
    credentials = random_password.tunnel_secret.result
  }

  type = "Opaque"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  account_id = var.cloudflare_account_id

  config {
    ingress_rule {
      hostname = "*.${var.ingress_domain}"
      service  = "http://traefik.ingress.svc.cluster.local"
      origin_request {
        no_tls_verify          = true
        connect_timeout        = "2m0s"
        keep_alive_connections = 100
        keep_alive_timeout     = "1m30s"
      }
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = kubernetes_namespace.ingress.metadata[0].name
    labels = {
      app = "cloudflared"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "cloudflared"
      }
    }

    template {
      metadata {
        labels = {
          app = "cloudflared"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "60123"
        }
      }

      spec {
        container {
          name  = "cloudflare"
          image = "cloudflare/cloudflared:latest"

          args = [
            "tunnel",
            "--metrics",
            "0.0.0.0:60123",
            "run",
            "--token",
            cloudflare_zero_trust_tunnel_cloudflared.tunnel.tunnel_token
          ]

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "cloudflared_hpa" {
  manifest = {
    apiVersion = "autoscaling/v2"
    kind       = "HorizontalPodAutoscaler"
    metadata = {
      name      = "cloudflared-hpa"
      namespace = kubernetes_namespace.ingress.metadata[0].name
    }
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = "cloudflared"
      }
      minReplicas = 1
      maxReplicas = 3
      metrics = [
        {
          type = "Resource"
          resource = {
            name = "cpu"
            target = {
              type               = "Utilization"
              averageUtilization = 80
            }
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_deployment.cloudflared]
}

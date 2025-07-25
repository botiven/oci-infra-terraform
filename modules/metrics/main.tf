resource "random_password" "grafana_admin_password" {
  length  = 32
  special = false
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "server.persistentVolume.enabled"
    value = "false"
  }

  set {
    name  = "server.replicaCount"
    value = "1"
  }

  set {
    name  = "alertmanager.enabled"
    value = "false"
  }
}

resource "kubernetes_manifest" "prometheus_ingressroute" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "prometheus"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      entryPoints = ["web", "websecure"]
      routes = [
        {
          match = "Host(`prometheus.${var.ingress_domain}`)"
          kind  = "Rule"
          services = [
            {
              kind = "Service"
              name = "prometheus-server"
              port = 80
            }
          ]
        }
      ]
    }
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      adminUser     = "saliven"
      adminPassword = random_password.grafana_admin_password.result

      presistence = {
        enabled = false
      }

      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name   = "Prometheus"
              type   = "prometheus"
              access = "proxy"
              url    = "http://prometheus-server.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
            }
          ]
        }
      }

      sidecar = {
        dashboards = {
          enabled         = true
          label           = "grafana_dashboard"
          folder          = "/tmp/dashboards"
          searchNamespace = kubernetes_namespace.monitoring.metadata[0].name
        }
      }
    })
  ]
}

resource "kubernetes_config_map" "grafana_dashboards" {
  for_each = fileset("${path.module}/grafana/dashboards", "*.json")

  metadata {
    name      = "dashboard-${replace(each.value, ".json", "")}"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "true"
    }
  }

  data = {
    "${each.value}" = file("${path.module}/grafana/dashboards/${each.value}")
  }

  depends_on = [kubernetes_namespace.monitoring]
}

resource "kubernetes_manifest" "grafana_ingressroute" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "grafana"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      entryPoints = ["web", "websecure"]
      routes = [
        {
          match = "Host(`grafana.${var.ingress_domain}`)"
          kind  = "Rule"
          services = [
            {
              kind = "Service"
              name = "grafana"
              port = 80
            }
          ]
        }
      ]
    }
  }
}

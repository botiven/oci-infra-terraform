resource "kubernetes_namespace" "clickhouse" {
  metadata {
    name = "clickhouse"
  }
}

resource "random_password" "clickhouse_password" {
  length  = 64
  special = false
}

resource "kubernetes_secret" "clickhouse" {
  metadata {
    name      = "clickhouse-credentials"
    namespace = kubernetes_namespace.clickhouse.metadata[0].name
  }

  type = "Opaque"

  data = {
    password = random_password.clickhouse_password.result
  }
}

resource "helm_release" "clickhouse" {
  name       = "clickhouse"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "clickhouse"
  version    = "7.1.0"
  namespace  = kubernetes_namespace.clickhouse.metadata[0].name

  values = [yamlencode({
    shards       = 2
    replicaCount = 1

    clusterName = "clickhouse-cluster"

    auth = {
      existingSecret    = kubernetes_secret.clickhouse.metadata[0].name
      existingSecretKey = "password"
    }

    persistence = {
      size = "50Gi"
    }

    resources = {
      limits = {
        cpu    = "2"
        memory = "10Gi"
      }
      requests = {
        cpu    = "500m"
        memory = "2Gi"
      }
    }

    zookeeper = {
      replicaCount = 1
    }

    metrics = {
      enabled = true
      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "8001"
      }
    }
  })]
}

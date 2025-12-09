# Prometheus & Grafana Stack Installation

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
    labels = {
      name       = var.monitoring_namespace
      managed-by = "terraform"
    }
  }
}

# Install kube-prometheus-stack via Helm
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  # Prometheus configuration
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  # Grafana configuration
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.service.type"
    value = var.grafana_service_type
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Create ServiceMonitor for backend app
resource "kubernetes_manifest" "backend_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "backend-metrics"
      namespace = var.app_namespace
      labels = {
        app     = "backend"
        release = "kube-prometheus-stack"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "backend"
        }
      }
      endpoints = [
        {
          port     = "metrics"
          path     = "/metrics"
          interval = "30s"
        }
      ]
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

# Create custom ConfigMap for Grafana dashboards
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "mind-app-dashboards"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "mind-app-dashboard.json"      = file("${path.module}/dashboards/mind-app-dashboard.json")
    "mind-notes-dashboard.json"    = file("${path.module}/dashboards/mind-notes-dashboard.json")
    "mind-auth-dashboard.json"     = file("${path.module}/dashboards/mind-auth-dashboard.json")
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

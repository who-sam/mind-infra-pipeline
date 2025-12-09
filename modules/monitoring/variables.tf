# modules/monitoring/variables.tf

variable "monitoring_namespace" {
  description = "Namespace for monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "app_namespace" {
  description = "Application namespace to monitor"
  type        = string
  default     = "notes-app"
}

variable "prometheus_chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "55.5.0"
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Prometheus storage size"
  type        = string
  default     = "50Gi"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "grafana_service_type" {
  description = "Grafana service type"
  type        = string
  default     = "LoadBalancer"
}

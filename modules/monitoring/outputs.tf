# modules/monitoring/outputs.tf

output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_url" {
  description = "Prometheus server URL"
  value       = "http://kube-prometheus-stack-prometheus.${kubernetes_namespace.monitoring.metadata[0].name}:9090"
}

output "grafana_url" {
  description = "Grafana server URL"
  value       = "Use: kubectl get svc kube-prometheus-stack-grafana -n ${kubernetes_namespace.monitoring.metadata[0].name}"
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = "admin"
}

output "prometheus_service_name" {
  description = "Prometheus service name"
  value       = "kube-prometheus-stack-prometheus"
}

output "grafana_service_name" {
  description = "Grafana service name"
  value       = "kube-prometheus-stack-grafana"
}

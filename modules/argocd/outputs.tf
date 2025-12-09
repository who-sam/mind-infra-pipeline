# modules/argocd/outputs.tf

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = "Use: kubectl get svc argocd-server -n ${kubernetes_namespace.argocd.metadata[0].name}"
}

output "argocd_admin_password" {
  description = "ArgoCD admin initial password"
  value       = try(data.kubernetes_secret.argocd_admin_password.data["password"], "")
  sensitive   = true
}

output "argocd_version" {
  description = "ArgoCD chart version"
  value       = var.argocd_chart_version
}

output "argocd_server_service_name" {
  description = "ArgoCD server service name"
  value       = "argocd-server"
}

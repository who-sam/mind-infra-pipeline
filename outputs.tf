# ============================================================================
# ROOT MODULE - outputs.tf
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = module.eks.node_group_id
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}


# Add these outputs to your existing outputs.tf

output "argocd_info" {
  description = "ArgoCD access information"
  value = var.enable_argocd ? {
    namespace       = module.argocd[0].argocd_namespace
    server_url      = module.argocd[0].argocd_server_url
    admin_user      = "admin"
    admin_password  = module.argocd[0].argocd_admin_password
  } : null
  sensitive = true
}

output "monitoring_info" {
  description = "Monitoring stack access information"
  value = var.enable_monitoring ? {
    namespace       = module.monitoring[0].monitoring_namespace
    prometheus_url  = module.monitoring[0].prometheus_url
    grafana_url     = module.monitoring[0].grafana_url
    grafana_user    = module.monitoring[0].grafana_admin_user
  } : null
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "access_services_commands" {
  description = "Commands to access services"
  value = <<-EOT
    # Get ArgoCD URL:
    kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    
    # Get ArgoCD admin password:
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    
    # Get Grafana URL:
    kubectl get svc kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    
    # Get Prometheus URL (port-forward):
    kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
  EOT
}

output "argocd_login_command" {
  description = "Command to login to ArgoCD CLI"
  value = var.enable_argocd ? "argocd login $(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d)" : null
  sensitive = true
}

output "eks_cluster_info" {
  description = "EKS cluster information"
  value = {
    name     = module.eks.cluster_name
    endpoint = module.eks.cluster_endpoint
    version  = module.eks.cluster_version
  }
}

output "vpc_info" {
  description = "VPC information"
  value = {
    vpc_id     = module.vpc.vpc_id
    vpc_cidr   = module.vpc.vpc_cidr
    private_subnets = module.vpc.private_subnet_ids
    public_subnets  = module.vpc.public_subnet_ids
  }
}

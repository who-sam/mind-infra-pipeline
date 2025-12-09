# modules/argocd/variables.tf

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "argocd_service_type" {
  description = "Service type for ArgoCD server"
  type        = string
  default     = "LoadBalancer"
}

variable "argocd_domain" {
  description = "Domain for ArgoCD server"
  type        = string
  default     = ""
}

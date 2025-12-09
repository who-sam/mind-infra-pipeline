# ============================================================================
# PROJECT STRUCTURE:
# terraform-eks-infrastructure/
# ├── main.tf
# ├── variables.tf
# ├── outputs.tf
# ├── backend.tf
# ├── providers.tf
# ├── terraform.tfvars
# ├── modules/
# │   ├── vpc/
# │   │   ├── main.tf
# │   │   ├── variables.tf
# │   │   └── outputs.tf
# │   ├── eks/
# │   │   ├── main.tf
# │   │   ├── variables.tf
# │   │   └── outputs.tf
# │   ├── security-groups/
# │   │   ├── main.tf
# │   │   ├── variables.tf
# │   │   └── outputs.tf
# │   └── iam/
# │       ├── main.tf
# │       ├── variables.tf
# │       └── outputs.tf
# ============================================================================
# ============================================================================
# ROOT MODULE - main.tf
# ============================================================================
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ============================================================================
# MODULES
# ============================================================================

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags                 = var.tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
  
  # Pass through the additional IAM users/roles
  additional_iam_users = var.additional_iam_users
  additional_iam_roles = var.additional_iam_roles
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"
  
  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  allowed_ssh_ips = var.allowed_ssh_ips
  tags            = var.tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  project_name              = var.project_name
  environment               = var.environment
  cluster_version           = var.cluster_version
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids         = module.vpc.public_subnet_ids
  cluster_role_arn          = module.iam.eks_cluster_role_arn
  node_role_arn             = module.iam.eks_node_role_arn
  cluster_security_group_id = module.security_groups.cluster_security_group_id
  node_security_group_id    = module.security_groups.node_security_group_id
  node_group_desired_size   = var.node_group_desired_size
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size
  node_instance_types       = var.node_instance_types
  node_disk_size            = var.node_disk_size
  enable_cluster_encryption = var.enable_cluster_encryption
  cluster_log_types         = var.cluster_log_types
  tags                      = var.tags
}

# ============================================================================
# EKS CLUSTER DATA SOURCES
# ============================================================================

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# ============================================================================
# RE-CONFIGURED PROVIDERS FOR EKS
# ============================================================================

# Re-configure Kubernetes provider for EKS cluster
provider "kubernetes" {
  alias = "eks"
  
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name,
      "--region",
      var.region
    ]
  }
}

# Re-configure Helm provider for EKS cluster
provider "helm" {
  alias = "eks"
  
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.aws_eks_cluster.cluster.name,
        "--region",
        var.region
      ]
    }
  }
}

# ============================================================================
# AWS-AUTH CONFIGMAP - Grant Console Access to EKS
# ============================================================================

resource "kubernetes_config_map_v1_data" "aws_auth" {
  provider = kubernetes.eks
  
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      [
        # EKS Node Role - Required for nodes to join cluster
        {
          rolearn  = module.iam.eks_node_role_arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups = [
            "system:bootstrappers",
            "system:nodes"
          ]
        }
      ],
      # Additional IAM roles from variables
      var.additional_iam_roles
    ))
    
    # Additional IAM users from variables
    mapUsers = yamlencode(var.additional_iam_users)
  }

  force = true

  depends_on = [
    module.eks
  ]
}

# ============================================================================
# KUBERNETES APPLICATIONS
# ============================================================================

# Install ArgoCD
module "argocd" {
  source = "./modules/argocd"
  
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
  
  argocd_namespace     = var.argocd_namespace
  argocd_chart_version = var.argocd_chart_version
  argocd_service_type  = var.argocd_service_type
  project_name         = var.project_name
  environment          = var.environment
  
  depends_on = [
    module.eks,
    kubernetes_config_map_v1_data.aws_auth
  ]
}

# Install Monitoring Stack (Prometheus & Grafana)
module "monitoring" {
  source = "./modules/monitoring"
  
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
  
  monitoring_namespace      = var.monitoring_namespace
  app_namespace            = var.app_namespace
  prometheus_chart_version = var.prometheus_chart_version
  prometheus_retention     = var.prometheus_retention
  prometheus_storage_size  = var.prometheus_storage_size
  grafana_admin_password   = var.grafana_admin_password
  grafana_service_type     = var.grafana_service_type
  project_name             = var.project_name
  environment              = var.environment
  
  depends_on = [
    module.eks,
    kubernetes_config_map_v1_data.aws_auth
  ]
}

# ============================================================================
# OUTPUTS
# ============================================================================

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

# MIND - Infrastructure Pipeline

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900.svg)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.34-326CE5.svg)](https://kubernetes.io/)

> Infrastructure as Code for provisioning production-ready AWS EKS clusters with Terraform.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Module Structure](#module-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Jenkins Pipeline](#jenkins-pipeline)
- [AWS Resources](#aws-resources)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This repository contains Terraform Infrastructure as Code (IaC) for deploying a complete, production-ready AWS EKS (Elastic Kubernetes Service) cluster with all necessary networking, security, and operational components.

### What Gets Deployed

✅ **VPC** - Multi-AZ networking with public/private subnets  
✅ **EKS Cluster** - Managed Kubernetes 1.34 control plane  
✅ **Node Groups** - Auto-scaling worker nodes (t3.medium)  
✅ **IAM** - Secure roles for cluster and nodes  
✅ **Security Groups** - Network isolation and access control  
✅ **KMS** - Encryption keys for secrets  
✅ **CloudWatch** - Centralized logging  
✅ **Load Balancers** - AWS ELB integration  

---

## 🏗️ Architecture

### Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Region: us-east-1                      │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     VPC (10.0.0.0/16)                     │  │
│  │                                                           │  │
│  │      Availability Zone A          Availability Zone B     │  │
│  │      ┌─────────────────┐          ┌─────────────────┐     │  │
│  │      │ Public Subnet   │          │ Public Subnet   │     │  │
│  │      │ 10.0.1.0/24     │          │ 10.0.2.0/24     │     │  │
│  │      │  - NAT Gateway  │          │  - NAT Gateway  │     │  │
│  │      │  - ALB          │          │  - ALB          │     │  │
│  │      └────────┬────────┘          └────────┬────────┘     │  │
│  │               │                            │              │  │
│  │      ┌────────▼────────┐          ┌────────▼────────┐     │  │
│  │      │ Private Subnet  │          │ Private Subnet  │     │  │
│  │      │ 10.0.11.0/24    │          │ 10.0.12.0/24    │     │  │
│  │      │  - EKS Nodes    │          │  - EKS Nodes    │     │  │
│  │      │  - Pods         │          │  - Pods         │     │  │
│  │      └─────────────────┘          └─────────────────┘     │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              EKS Control Plane (Managed by AWS)           │  │
│  │          - API Server    - Controller Manager             │  │
│  │          - Scheduler     - etcd (encrypted)               │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Component Interaction

```
Terraform Root Module
    │
    ├─  VPC Module (Networking)
    │   ├─ VPC (10.0.0.0/16)
    │   ├─ Internet Gateway
    │   ├─ NAT Gateways (2x)
    │   ├─ Public Subnets (2x)
    │   ├─ Private Subnets (2x)
    │   └─ Route Tables
    │
    ├─  IAM Module (Security)
    │   ├─ EKS Cluster Role
    │   ├─ EKS Node Role
    │   └─ Policy Attachments
    │
    ├─  Security Groups Module
    │   ├─ Cluster Security Group
    │   ├─ Node Security Group
    │   └─ Ingress/Egress Rules
    │
    └─  EKS Module (Kubernetes)
        ├─ EKS Cluster
        ├─ Node Groups (Multi-AZ)
        ├─ KMS Encryption
        ├─ CloudWatch Logging
        └─ aws-auth ConfigMap
```

---

## 📁 Module Structure

```
mind-infra-pipeline/
├── main.tf                      # Root orchestration
├── providers.tf                 # AWS & Kubernetes providers
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── backend.tf                   # S3 remote state
├── terraform.tfvars             # Configuration values
├── Jenkinsfile                  # CI/CD pipeline
│
├── modules/
│   ├── vpc/                     # Networking Module
│   │   ├── main.tf              # VPC, subnets, gateways
│   │   ├── variables.tf         # VPC inputs
│   │   └── outputs.tf           # VPC outputs
│   │
│   ├── iam/                     # IAM Module
│   │   ├── main.tf              # IAM roles
│   │   ├── variables.tf         # IAM inputs
│   │   └── outputs.tf           # Role ARNs
│   │
│   ├── security-groups/         # Security Module
│   │   ├── main.tf              # Security groups
│   │   ├── variables.tf         # Security inputs
│   │   └── outputs.tf           # SG IDs
│   │
│   └── eks/                     # EKS Module
│       ├── main.tf              # Cluster & nodes
│       ├── variables.tf         # EKS inputs
│       └── outputs.tf           # Cluster outputs
│
├── .terraform.lock.hcl          # Provider version lock
└── README.md                    # This file
```

---

## ✅ Prerequisites

### Required Tools

| Tool | Version | Installation |
|------|---------|--------------|
| **Terraform** | 1.0+ | [Download](https://www.terraform.io/downloads) |
| **AWS CLI** | 2.x | [Download](https://aws.amazon.com/cli/) |
| **kubectl** | 1.28+ | [Download](https://kubernetes.io/docs/tasks/tools/) |
| **Git** | Latest | [Download](https://git-scm.com/) |

### AWS Requirements

- AWS account with admin privileges
- IAM user or role with permissions:
  - EC2, VPC, EKS, IAM, KMS, CloudWatch, S3

### AWS CLI Configuration
```bash
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: us-east-1
# Default output format: json
```

---

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/who-sam/mind-infra-pipeline.git
cd mind-infra-pipeline
```

### 2. Configure Variables

Edit `terraform.tfvars`:
```hcl
# Project Configuration
project_name = "my-eks-project"
environment  = "dev"
aws_region   = "us-east-1"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

# EKS Configuration
cluster_version         = "1.34"
node_group_desired_size = 3
node_group_min_size     = 3
node_group_max_size     = 6
node_instance_types     = ["t3.medium"]

# IAM Access (IMPORTANT: Add your IAM user ARN)
additional_iam_users = [
  {
    userarn  = "arn:aws:iam::YOUR_ACCOUNT:user/YOUR_USERNAME"
    username = "YOUR_USERNAME"
    groups   = ["system:masters"]
  }
]
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Plan Infrastructure
```bash
terraform plan -out=tfplan
```

Review the plan carefully before applying.

### 5. Deploy Infrastructure
```bash
terraform apply tfplan
```

**Expected time**: 15-20 minutes

### 6. Configure kubectl
```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name my-eks-project-dev-cluster
```

### 7. Verify Cluster
```bash
kubectl get nodes
kubectl get pods -A
```

---

## ⚙️ Configuration

### Key Variables

#### Project Settings
```hcl
project_name = "my-eks-project"  # Project identifier
environment  = "dev"             # Environment: dev/staging/prod
aws_region   = "us-east-1"       # AWS region
```

#### VPC Settings
```hcl
vpc_cidr             = "10.0.0.0/16"                    # VPC CIDR
availability_zones   = ["us-east-1a", "us-east-1b"]    # AZs
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]  # Public subnets
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"] # Private subnets
enable_nat_gateway   = true                             # Enable NAT
single_nat_gateway   = false                            # NAT per AZ
```

#### EKS Settings
```hcl
cluster_version           = "1.34"          # Kubernetes version
node_group_desired_size   = 3               # Desired nodes
node_group_min_size       = 3               # Min nodes
node_group_max_size       = 6               # Max nodes
node_instance_types       = ["t3.medium"]   # Instance type
node_disk_size            = 20              # Disk size (GB)
enable_cluster_encryption = true            # KMS encryption
cluster_log_types         = [               # CloudWatch logs
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]
```

#### IAM Access Configuration

**Critical**: Grant console access to EKS cluster:

```hcl
additional_iam_users = [
  {
    userarn  = "arn:aws:iam::123456789012:user/admin"
    username = "admin"
    groups   = ["system:masters"]  # Full admin access
  },
  {
    userarn  = "arn:aws:iam::123456789012:user/developer"
    username = "developer"
    groups   = ["developers"]  # Custom group
  }
]

additional_iam_roles = [
  {
    rolearn  = "arn:aws:iam::123456789012:role/DevOpsRole"
    username = "devops-role"
    groups   = ["system:masters"]
  }
]
```

**How to get your IAM ARN:**
```bash
aws sts get-caller-identity
```

### Backend Configuration

Terraform state is stored in S3:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket  = "hello-devops-production-terraform-state-who"
    key     = "eks/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}
```

---

## 🔄 Jenkins Pipeline

### Pipeline Overview

The Jenkinsfile automates infrastructure deployment:

```groovy
Stage 1: Checkout Code
    └─ Clones repository from GitHub

Stage 2: Terraform Init
    └─ Initializes providers and modules

Stage 3: Terraform Plan
    └─ Creates execution plan

Stage 4: Terraform Apply (Commented Out)
    └─ Applies infrastructure changes

Stage 5: Terraform Destroy
    └─ Tears down infrastructure
```

### Jenkins Setup

1. **Create Pipeline Job**
```bash
# In Jenkins UI:
# New Item → Pipeline
# Pipeline script from SCM
# SCM: Git
# Repository URL: https://github.com/who-sam/mind-infra-pipeline.git
# Branch: main
```

2. **Configure AWS Credentials**
```bash
# In Jenkins:
# Manage Jenkins → Credentials
# Add AWS credentials (access key + secret)
```

3. **Configure GitHub Webhook**
```bash
# In GitHub repository settings:
# Webhooks → Add webhook
# Payload URL: http://jenkins-url/github-webhook/
# Content type: application/json
# Events: Push events
```

4. **Run Pipeline**
```bash
# Automatically triggered on push
# Or manually: Build Now
```

### Pipeline Configuration

To enable automatic apply, uncomment lines 44-60 in `Jenkinsfile`:

```groovy
stage('Terraform Apply') {
    steps {
        echo "🔹 Applying Terraform..."
        sh 'terraform apply -auto-approve tfplan'
        echo "✅ Infrastructure deployed successfully!"
    }
}
```

---

## ☁️ AWS Resources

### Created Resources

| Resource | Count | Details |
|----------|-------|---------|
| **VPC** | 1 | 10.0.0.0/16 CIDR |
| **Subnets** | 4 | 2 public + 2 private |
| **Internet Gateway** | 1 | For public internet |
| **NAT Gateways** | 2 | One per AZ |
| **EKS Cluster** | 1 | Managed control plane |
| **Node Groups** | 2 | One per AZ |
| **EC2 Instances** | 3-6 | t3.medium workers |
| **Security Groups** | 2 | Cluster + nodes |
| **IAM Roles** | 2 | Cluster + nodes |
| **KMS Keys** | 1 | For encryption |
| **CloudWatch Log Groups** | 1 | EKS logs |

### Estimated Costs

| Service | Monthly Cost (us-east-1) |
|---------|------------------------|
| EKS Cluster | $72 |
| EC2 (3x t3.medium) | ~$93 |
| NAT Gateway (2x) | ~$90 |
| EBS Volumes | ~$6 |
| Data Transfer | ~$10 |
| **Total** | **~$271/month** |

*Costs are approximate and may vary.*

---

## 🔍 Outputs

After successful deployment, Terraform outputs:

```bash
# View all outputs
terraform output

# Outputs:
vpc_id = "vpc-xxxxx"
eks_cluster_id = "my-eks-project-dev-cluster"
eks_cluster_endpoint = "https://xxxxx.eks.us-east-1.amazonaws.com"
eks_cluster_name = "my-eks-project-dev-cluster"
configure_kubectl = "aws eks update-kubeconfig --region us-east-1 --name my-eks-project-dev-cluster"
```

---

## 🛠️ Operations

### Update Infrastructure

```bash
# Make changes to .tf files or terraform.tfvars
vim terraform.tfvars

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### Upgrade Kubernetes Version

```bash
# Edit terraform.tfvars
cluster_version = "1.32"  # Update version

# Apply upgrade
terraform plan
terraform apply
```

### Scale Node Group

```bash
# Edit terraform.tfvars
node_group_desired_size = 5
node_group_max_size     = 10

# Apply scaling
terraform apply
```

### Destroy Infrastructure

```bash
# Destroy all resources
terraform destroy

# Or via Jenkins:
# Run pipeline with destroy stage enabled
```

---

## 🐛 Troubleshooting

### Issue: State Lock Error
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Force unlock (use carefully)
terraform force-unlock <lock-id>

# Or wait for timeout (2 minutes)
```

### Issue: VPC CIDR Conflict
```
Error: VPC CIDR conflicts with existing VPC
```

**Solution:**
```hcl
# Change CIDR in terraform.tfvars
vpc_cidr = "10.1.0.0/16"  # Use different range
```

### Issue: Insufficient Capacity
```
Error: Insufficient capacity in availability zone
```

**Solution:**
```hcl
# Try different AZs
availability_zones = ["us-east-1a", "us-east-1c"]

# Or different instance type
node_instance_types = ["t3.small"]
```

### Issue: Cannot Access EKS Console
```
Your current user or role does not have access
```

**Solution:**
```hcl
# Add your IAM user ARN to terraform.tfvars
additional_iam_users = [
  {
    userarn  = "arn:aws:iam::123456789012:user/YOUR_USER"
    username = "YOUR_USER"
    groups   = ["system:masters"]
  }
]

# Apply changes
terraform apply
```

### Debug Mode

Enable verbose logging:
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform plan
```

View CloudWatch logs:
```bash
aws logs tail /aws/eks/my-eks-project-dev-cluster/cluster --follow
```

---

## 📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## 🔗 Related Repositories

- **Source Code**: [MIND](https://github.com/who-sam/MIND)
- **CI Pipeline**: [mind-ci-pipeline](https://github.com/who-sam/mind-ci-pipeline)
- **ArgoCD**: [mind-argocd-pipeline](https://github.com/who-sam/mind-argocd-pipeline)


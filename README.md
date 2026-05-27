# Terraform AWS EKS Infrastructure

This project provisions a complete AWS EKS (Elastic Kubernetes Service) infrastructure using Terraform, including VPC, EKS cluster, and necessary IAM roles for Kubernetes add-ons.

## Architecture Overview

The infrastructure consists of three main components:

1. **Bootstrap** - S3 bucket and DynamoDB table for Terraform remote state management
2. **VPC** - Network infrastructure with public, private, and isolated subnets
3. **EKS** - Kubernetes cluster with managed node groups and IRSA (IAM Roles for Service Accounts)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.48.0 (for Terragrunt deployment)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (optional, for manual cluster access)
- AWS account with permissions to create VPC, EKS, IAM, S3, and DynamoDB resources

**Important:** This guide uses Terragrunt v1.0+ syntax:

```bash
# Deploy all modules
terragrunt run --all apply

# Plan all modules
terragrunt run --all plan

# Destroy all modules
terragrunt run --all destroy
```

See [TERRAGRUNT_V1_GUIDE.md](TERRAGRUNT_V1_GUIDE.md) for more details.

## Quick Start (TL;DR)

**Deploy everything with Terragrunt v1.0+:**

```bash
# 1. Install Terragrunt
wget https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

# 2. Deploy all infrastructure (one command!)
cd environments/dev
terragrunt run --all apply

# 3. Get application URL (wait 2-3 minutes for ALB)
cd app
terragrunt refresh && terragrunt output application_url

# 4. Test
curl $(terragrunt output -raw application_url)
```

**That's it!** ✅ No manual IAM setup, no kubectl configuration needed.

**Time:** ~25-30 minutes for full deployment.

**Note:** Terragrunt v1.0+ uses `terragrunt run --all <command>` to run on all modules.

## Project Structure

```
terraform/
├── bootstrap/          # Remote state backend setup
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── vpc/               # VPC and networking
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── eks/               # EKS cluster and node groups
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── irsa.tf       # IAM roles for service accounts
│   └── alb-controller-policy.json
└── app/               # Kubernetes manifests
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

## Deployment Steps

### Option 1: Terragrunt (Recommended - DRY & Multi-Environment)

Terragrunt provides better code organization, eliminates duplication, and simplifies multi-environment management.

#### Prerequisites
```bash
# Install Terragrunt
wget https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

# Verify installation
terragrunt --version
```

#### Quick Deploy (All modules)

**🚀 Fully Automated - One Command!**

```bash
# Deploy everything: bootstrap → vpc → eks → app
cd environments/dev
terragrunt run --all apply
```

**That's it!** ✅ 

The deployment is **fully automated**:
- ✅ EKS cluster automatically grants admin permissions to the creator (no manual IAM setup needed)
- ✅ App module automatically configures kubectl via Kubernetes provider (no `aws eks update-kubeconfig` needed)
- ✅ ALB Controller is deployed automatically via Helm
- ✅ Application is deployed and ALB URL is displayed in outputs

**Time:** ~25-30 minutes

**After deployment completes:**

```bash
# Get the application URL
cd environments/dev/app
terragrunt output application_url

# Or refresh to get the latest ALB URL (if it was still provisioning)
terragrunt refresh && terragrunt output application_url

# Test the application
curl $(terragrunt output -raw application_url)
```

**Optional - For manual kubectl access:**

If you want to use `kubectl` commands manually (not required for deployment):

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name dev-vsf-tts
kubectl get nodes
kubectl get pods
kubectl get ingress
```

**Note:** Terragrunt v1.0+ uses `terragrunt run --all <command>` to run commands on all modules in dependency order.

#### Step-by-Step Deploy (Recommended for first time)

If you prefer to understand each step:

```bash
# 1. Bootstrap (S3 + DynamoDB for state storage)
cd environments/dev/bootstrap
terragrunt apply

# 2. VPC (Network infrastructure)
cd ../vpc
terragrunt apply

# 3. EKS (Kubernetes cluster with auto admin permissions)
cd ../eks
terragrunt apply
# ✅ No manual IAM setup needed - cluster creator gets admin automatically!

# 4. App (Deploy application with auto kubectl config)
cd ../app
terragrunt apply
# ✅ No 'aws eks update-kubeconfig' needed - Kubernetes provider handles it!

# 5. Get the application URL
terragrunt output application_url

# Or wait for ALB and refresh
sleep 120  # Wait 2 minutes for ALB
terragrunt refresh && terragrunt output application_url
```

**That's it!** No manual steps required.

**Optional - Configure kubectl for manual use:**

```bash
# Only if you want to use kubectl commands manually
aws eks update-kubeconfig --region ap-southeast-1 --name dev-vsf-tts
kubectl get pods
kubectl get ingress
```

#### Automated Script
```bash
# Use the provided script
chmod +x terragrunt-deploy.sh
./terragrunt-deploy.sh dev
```

**Time:** ~25-30 minutes

**Benefits:**
- ✅ **Fully automated deployment** - No manual IAM or kubectl configuration needed
- ✅ **DRY configuration** - No repeated backend/provider code
- ✅ **Automatic dependency management** - Correct deployment order guaranteed
- ✅ **Easy multi-environment setup** - Copy `dev` to `staging` or `prod`
- ✅ **Centralized variable management** - All config in `env.hcl`
- ✅ **Infrastructure as Code** - Everything versioned and reproducible

**Key Features:**
- 🔐 **Auto IAM permissions**: `enable_cluster_creator_admin_permissions = true` in EKS module
- 🔧 **Auto kubectl config**: Kubernetes provider in app module handles authentication
- 📦 **State management**: S3 backend with DynamoDB locking
- 🔄 **Dependency graph**: Terragrunt ensures correct deployment order

**Documentation:**
- 📖 **[HUONG_DAN_TERRAGRUNT.md](HUONG_DAN_TERRAGRUNT.md)** - Detailed guide in Vietnamese
- 📖 **[QUICK_START_TERRAGRUNT.md](QUICK_START_TERRAGRUNT.md)** - Quick reference
- 📖 **[README_TERRAGRUNT.md](README_TERRAGRUNT.md)** - Overview and getting started
- 📖 **[GIAI_THICH_KUBECTL_CONFIG.md](GIAI_THICH_KUBECTL_CONFIG.md)** - Why kubectl auto-configuration works
- 📖 **[CAU_TRUC_PROJECT.md](CAU_TRUC_PROJECT.md)** - Project structure explained

---

### Why No Manual Steps Are Needed?

#### 1. No Manual IAM Access Grant Required

**EKS Module Configuration:**
```hcl
# terraform/eks/main.tf
module "eks" {
  enable_cluster_creator_admin_permissions = true  # ← This is the magic!
}
```

**What this does:**
- Automatically grants admin permissions to the IAM principal (user/role) that creates the cluster
- No need to run `aws eks create-access-entry` or `aws eks associate-access-policy`
- Works immediately after cluster creation

#### 2. No Manual kubectl Configuration Required

**App Module Configuration:**
```hcl
# terraform/app/main.tf
provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(...)
  
  exec {
    command = "aws"
    args    = ["eks", "get-token", "--cluster-name", "..."]
  }
}
```

**What this does:**
- Terraform's Kubernetes provider automatically authenticates with the EKS cluster
- Uses AWS CLI to get authentication tokens dynamically
- No need to run `aws eks update-kubeconfig`
- No need to run `kubectl apply` - Terraform manages Kubernetes resources directly

#### 3. Complete Automation Flow

```
terragrunt run --all apply
         ↓
    Bootstrap (S3 + DynamoDB)
         ↓
    VPC (Network)
         ↓
    EKS (Cluster with auto admin permissions)
         ↓
    App (Kubernetes resources via provider)
         ↓
    ✅ Done! Application URL in outputs
```

**No manual intervention needed at any step!**

**Terragrunt v1.0+ Commands:**
- `terragrunt run --all apply` - Deploy all modules
- `terragrunt run --all plan` - Plan all modules
- `terragrunt run --all destroy` - Destroy all modules
- `terragrunt run --all output` - Show outputs from all modules

---

### Option 2: Terraform (Traditional)

#### Quick Start (Automated)

For a fully automated deployment, use the provided script:

```bash
./deploy-all.sh
```

This script will:
1. Deploy Bootstrap (S3 + DynamoDB)
2. Deploy VPC
3. Deploy EKS cluster
4. Grant IAM access automatically
5. Deploy ALB Controller
6. Deploy sample application

**Time:** ~25-30 minutes

#### Manual Deployment (Step-by-Step)

If you prefer to deploy manually or understand each step:

#### 1. Bootstrap (Remote State Backend)

First, create the S3 bucket and DynamoDB table for storing Terraform state:

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```

**Note:** The bootstrap state is stored locally. After creation, you can optionally migrate it to the S3 backend.

#### 2. VPC

Create the VPC with public, private, and isolated subnets:

```bash
cd ../vpc
terraform init
terraform plan
terraform apply
```

This creates:
- VPC with CIDR 10.0.0.0/16
- 2 public subnets (for ALB)
- 2 private subnets (for EKS nodes)
- 2 isolated subnets (for databases)
- NAT Gateway for private subnet internet access
- Proper tags for EKS subnet discovery

#### 3. EKS Cluster

Create the EKS cluster with managed node groups:

```bash
cd ../eks
terraform init
terraform plan
terraform apply
```

This creates:
- EKS cluster (Kubernetes 1.30)
- Managed node group with Spot instances
- EBS CSI driver with IRSA
- IAM roles for service accounts (EBS CSI, ALB Controller)
- AWS Load Balancer Controller (automatically deployed via Helm)
- **Automatic cluster creator admin permissions** (no manual IAM setup needed!)

**Expected time:** ~15-20 minutes (EKS cluster creation takes the longest)

**Note:** The cluster automatically grants admin permissions to the IAM principal that creates it (`enable_cluster_creator_admin_permissions = true`), so the ALB Controller will deploy successfully in a **single apply**.

**Verification:**
```bash
# Check ALB Controller pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Should show 2 pods running:
# NAME                                            READY   STATUS    RESTARTS   AGE
# aws-load-balancer-controller-xxxxxxxxx-xxxxx    1/1     Running   0          2m
# aws-load-balancer-controller-xxxxxxxxx-yyyyy    1/1     Running   0          2m
```

#### 4. Configure kubectl

After EKS creation, configure kubectl to access the cluster:

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name dev-vsf-tts
```

Verify access:

```bash
kubectl get nodes
```

#### 5. Deploy Applications

Deploy the sample nginx application:

```bash
cd ../app
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

## Configuration

### Default Values

All modules use sensible defaults defined in `variables.tf` files:

- **Region:** ap-southeast-1
- **Project Name:** dev-vsf-tts
- **Environment:** dev
- **EKS Version:** 1.30
- **Node Type:** Spot instances (t3.medium, t3.large, t3a.medium)
- **Node Count:** 2 (min: 1, max: 3)

### Customization

To customize values, create a `terraform.tfvars` file in each module directory:

```hcl
# terraform/vpc/terraform.tfvars
region         = "us-west-2"
project_name   = "my-project"
environment    = "production"
vpc_cidr       = "10.1.0.0/16"
single_nat_gateway = false  # Use multiple NAT gateways for HA
```

```hcl
# terraform/eks/terraform.tfvars
cluster_name       = "my-cluster"
cluster_version    = "1.31"
node_capacity_type = "ON_DEMAND"  # Use on-demand instead of spot
node_desired_size  = 3
```

## Important Notes

### Cost Optimization

- **Single NAT Gateway:** By default, uses one NAT gateway to save costs (~$32/month). For production, set `single_nat_gateway = false` for high availability.
- **Spot Instances:** Node groups use Spot instances for ~70% cost savings. For production workloads, consider using `ON_DEMAND` capacity type.

### Security Considerations

- EKS API endpoint is publicly accessible. For production, consider restricting access with `cluster_endpoint_public_access_cidrs`.
- State files contain sensitive data and are encrypted in S3.
- Never commit `*.tfvars` files containing secrets to version control.

### State Management

- Bootstrap state is stored locally
- VPC and EKS states are stored in S3 with DynamoDB locking
- State files are encrypted at rest

## Cleanup

To destroy the infrastructure (in reverse order):

**Using Terragrunt:**

```bash
# Destroy all modules in reverse dependency order
cd environments/dev
terragrunt run --all destroy
```

**Using Terraform (Traditional):**

```bash
# Delete Kubernetes resources first
kubectl delete -f terraform/app/

# Destroy EKS cluster
cd terraform/eks
terraform destroy

# Destroy VPC
cd ../vpc
terraform destroy

# Destroy bootstrap (optional - will delete state storage)
cd ../bootstrap
terraform destroy
```

## Troubleshooting

### Issue: "Application URL shows 'Pending'"

**Cause:** ALB takes 2-3 minutes to provision after Ingress is created.

**Solution:**
```bash
# Wait 2-3 minutes, then refresh Terraform state
cd environments/dev/app
terragrunt refresh && terragrunt output application_url

# Or check with kubectl
kubectl get ingress -n default
```

### Issue: "Kubernetes cluster unreachable"

**Cause:** This should NOT happen with the current setup because `enable_cluster_creator_admin_permissions = true` is set.

**Verify the setting:**
```bash
grep "enable_cluster_creator_admin_permissions" terraform/eks/main.tf
# Should show: enable_cluster_creator_admin_permissions = true
```

**If you still see this error (rare):**
```bash
# Manually grant access (only if automatic method failed)
USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
aws eks create-access-entry --cluster-name dev-vsf-tts --principal-arn $USER_ARN --region ap-southeast-1
aws eks associate-access-policy --cluster-name dev-vsf-tts --principal-arn $USER_ARN \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster --region ap-southeast-1
```

### Issue: "Cluster already exists with name: dev-vsf-tts"

**Cause:** The cluster already exists in AWS but not in Terraform state.

**Solution:** 
```bash
# Check if cluster exists
aws eks describe-cluster --name dev-vsf-tts --region ap-southeast-1

# If it exists, destroy it first
cd terraform/eks
terraform destroy

# Or delete manually via AWS Console/CLI
aws eks delete-cluster --name dev-vsf-tts --region ap-southeast-1
```

### Issue: ALB Controller pods not starting

**Cause:** IAM role not properly configured or IRSA not working.

**Solution:**
```bash
# 1. Check if ALB Controller pods exist
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# 2. Check IAM role exists
aws iam get-role --role-name dev-vsf-tts-alb-controller

# 3. Check OIDC provider is configured
aws eks describe-cluster --name dev-vsf-tts --region ap-southeast-1 --query 'cluster.identity.oidc.issuer'

# 4. Check pod logs for errors
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=50

# 5. If pods are not running, re-apply EKS module
cd environments/dev/eks
terragrunt apply
```

### Issue: Ingress not creating ALB

**Cause:** ALB Controller not running, missing permissions, or incorrect annotations.

**Solution:**
```bash
# 1. Verify ALB Controller is running
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
# Should show 2 pods in Running state

# 2. Check ingress status and events
kubectl describe ingress nginx -n default

# 3. Check ALB Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=100

# 4. Verify ingress annotations
kubectl get ingress nginx -n default -o yaml | grep -A 5 annotations

# 5. If still not working, re-apply app module
cd environments/dev/app
terragrunt destroy
terragrunt apply
```

### Issue: "Error: Backend configuration changed"

**Cause:** Terraform backend configuration has changed.

**Solution:**
```bash
terragrunt init -reconfigure
```

### Issue: "Error: acquiring the state lock"

**Cause:** Previous Terraform run was interrupted and left a lock.

**Solution:**
```bash
# Get the lock ID from the error message, then:
terragrunt force-unlock <LOCK_ID>
```

### Getting Help

**Check deployment status:**
```bash
# Check all modules at once
cd environments/dev
terragrunt run --all output

# Or check each module individually
cd bootstrap && terragrunt output && cd ..
cd vpc && terragrunt output && cd ..
cd eks && terragrunt output && cd ..
cd app && terragrunt output application_url && cd ..
```

**Verify resources in AWS:**
```bash
# Check EKS cluster
aws eks describe-cluster --name dev-vsf-tts --region ap-southeast-1

# Check load balancers
aws elbv2 describe-load-balancers --region ap-southeast-1

# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=dev-vsf-tts*" --region ap-southeast-1
```

**Check Kubernetes resources:**
```bash
# Configure kubectl (if not already done)
aws eks update-kubeconfig --region ap-southeast-1 --name dev-vsf-tts

# Check all resources
kubectl get all -A
kubectl get ingress -A
kubectl get nodes

# Check specific namespace
kubectl get all -n default
kubectl get events -n default --sort-by='.lastTimestamp'
```

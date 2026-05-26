# Terraform AWS EKS Infrastructure

This project provisions a complete AWS EKS (Elastic Kubernetes Service) infrastructure using Terraform, including VPC, EKS cluster, and necessary IAM roles for Kubernetes add-ons.

## Architecture Overview

The infrastructure consists of three main components:

1. **Bootstrap** - S3 bucket and DynamoDB table for Terraform remote state management
2. **VPC** - Network infrastructure with public, private, and isolated subnets
3. **EKS** - Kubernetes cluster with managed node groups and IRSA (IAM Roles for Service Accounts)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with permissions to create VPC, EKS, IAM, S3, and DynamoDB resources

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

### 1. Bootstrap (Remote State Backend)

First, create the S3 bucket and DynamoDB table for storing Terraform state:

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```

**Note:** The bootstrap state is stored locally. After creation, you can optionally migrate it to the S3 backend.

### 2. VPC

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

### 3. EKS Cluster

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
- IAM role for AWS Load Balancer Controller
- AWS Load Balancer Controller (via Helm)

**Important:** If you already have the AWS Load Balancer Controller installed manually, you need to import it into Terraform state. See `terraform/eks/IMPORT_ALB_CONTROLLER.md` for detailed instructions.

Quick import command:
```bash
cd terraform/eks
terraform import helm_release.aws_load_balancer_controller kube-system/aws-load-balancer-controller
```

### 4. Configure kubectl

After EKS creation, configure kubectl to access the cluster:

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name dev-vsf-tts
```

Verify access:

```bash
kubectl get nodes
```

### 5. Deploy Applications

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

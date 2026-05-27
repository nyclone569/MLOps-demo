# AWS EKS Infrastructure — Summary

## Project Overview

Built a production-like AWS infrastructure from scratch using Terraform,
deploying a containerized web application on EKS and exposing it to
the internet via an Application Load Balancer.

**Stack:** Terraform · AWS · Kubernetes · Helm · GitHub (mono repo)

---

## Phase 1 — Bootstrap: S3 + DynamoDB

Terraform tracks the current state of infrastructure in `terraform.tfstate`
to calculate what needs to be added, changed, or destroyed on each run.

**Problem:** storing state locally introduces two risks:
- Two people running `terraform apply` simultaneously can corrupt state
- Losing the local file means losing track of all managed resources

**Solution:**
- **S3** stores `terraform.tfstate` as a shared remote backend.  S3 is AWS object storage (key/value pairs) also commonly used for  static web hosting, data lakes, and backups.
- **DynamoDB** acts as a lock table via conditional writes — only one `apply` can hold the lock at a time; concurrent operators must wait. DynamoDB is a serverless NoSQL database also used for session stores, leaderboards, and real-time data.

**Alternative at scale:** Terraform Cloud / HCP Terraform provides
built-in remote state, locking, and run history without managing
S3 and DynamoDB manually.

---

## Phase 2 — VPC & Networking

Designed a three-tier network model inside a single VPC across two Availability Zones for high availability.

### Subnet types

| Type  | Contains | Internet access |
|---|---|---|
| Public  | ALB, NAT Gateway | Inbound + outbound via IGW |
| Private | EKS nodes, pods | Outbound only via NAT |
| Isolated | Databases, caches | None |

- **Public subnet** is attached to the Internet Gateway. Only the ALB and NAT Gateway live here — no application workloads.
- **Private subnet** has no public IP. Pods reach the internet  (to pull images from ECR, call AWS APIs) through the NAT Gateway.  Resources in private subnets cannot be reached directly from the internet because they do not have public IPs or routes through an Internet Gateway.
- **Isolated subnet** has no route to the internet in either direction. Resources here (RDS, ElastiCache) have no direct internet connectivity and are typically reachable only through private network paths inside AWS infrastructure. **Unused in this project** but provisioned following best practice.

### Gateways

- **Internet Gateway (IGW):** attached to the VPC, enables two-way traffic for resources that have a public IP (such as the ALB).
- **NAT Gateway:** sits in the public subnet, allows private subnet resources to initiate outbound connections while remaining unreachable from the internet.


## Phase 3 — EKS + Addons

EKS is AWS's managed Kubernetes service. AWS provisions and manages
the control plane (kube-apiserver, etcd, scheduler, controller-manager),
which is accessible through the Kubernetes API (commonly via  `kubectl` ).

### Core addons

| Addon | Role | 
|---|---|
| `coredns` | In-cluster DNS; pods use it to resolve service names | 
| `kube-proxy` | programs iptables/IPVS rules so Service virtual IPs can forward traffic to backing pods |
| `vpc-cni` | Assigns real VPC IP addresses directly to pods | 
| `aws-ebs-csi-driver` | Provides EBS-backed PersistentVolumes | 

**Note on vpc-cni:** also have prefix delegation, custom networking, security groups for pods, but doesn't use in this demo.
### AWS Load Balancer Controller (LBC)

Runs inside the cluster and watches the API server for Ingress objects.
Based on annotations, it provisions and configures an ALB — including
listener rules, target groups, routing by path/host, health checks,
and protocol settings.

LBC requires **IRSA (IAM Role for Service Accounts)** — a mechanism
that binds a Kubernetes ServiceAccount to an AWS IAM role, granting
the pod permission to manage AWS resources. The IAM role must be
attached before installing the Helm chart.

---

## Phase 4 — Node Group with Spot Instances

### On-demand vs Spot

- **On-demand:** stable, not subject to interruption, higher cost.
- **Spot:** uses AWS's spare EC2 capacity at ~70% discount, but AWS
  can reclaim the instance with only a 2-minute warning.

### Handling spot interruption

Declaring multiple instance types (e.g. `t3.medium`, `t3.large`,
`t3a.medium`) increases the chance of finding available capacity.
When a node is reclaimed, replacement pods are scheduled onto remaining healthy nodes while the ASG provisions a new node in parallel.

### Auto Scaling Group (ASG)

`eks_managed_node_group` provisions an ASG driven by three values:
- **min_size**     = 1   # floor — never scale below this
- **desired_size** = 2   # target node count
- **max_size**     = 3   # ceiling — never scale above this

When a spot node is reclaimed, ASG detects that actual count is below
desired and automatically requests a replacement EC2 instance.

### Node Termination Handler (NTH)

An optional DaemonSet (one pod per node) that listens for AWS spot
interruption notices. On receiving a notice, NTH cordons the node
(blocks new scheduling) and drains existing pods to Pending state.
The scheduler then places them on healthy nodes. NTH must be installed
separately — it is not included by default.

### Autoscaling options

- **Cluster Autoscaler + HPA:** adjusts desired node count based on
  resource utilization and scales pod replicas horizontally.
- **Karpenter:** a more flexible node provisioner that provisions  nodes directly based on pending pod requirements, without requiring predefined node groups.

---

## Phase 5 — Deploy & Expose

### Kubernetes objects

- **Deployment:** manages pod lifecycle — replica count, rolling
  updates, restarts. Attaches labels to pods for service discovery.
- **Service:** provides a stable internal endpoint that routes traffic
  to pods matching a label selector, abstracting away individual pod IPs.
- **Ingress:** defines routing rules (host/path → service). The LBC
  reads these rules and configures ALB listener rules accordingly.
  A single Ingress object can hold multiple routing rules.

### Traffic flow

**Inbound (user → app)**

Internet → IGW → ALB (matches listener rules) → Service (routes by label selector) → Pod (private subnet) → response follows the same path back

**Outbound (pod → AWS API / ECR)**

Pod (private subnet) → NAT Gateway (public subnet) → IGW → Internet

---

## Alternatives Considered

**Terragrunt**
A thin wrapper around Terraform designed for multi-folder monorepos.
Handles dependency resolution, backend config generation, and output
injection between layers automatically.

**CDKTF (Cloud Development Kit for Terraform)**
allow you to use familiar programming languages to define and provision infrastructure. Write infrastructure in
TypeScript, Python, Go, Java, or C# — CDKTF synthesizes it into
Terraform JSON config, then the Terraform engine takes over.

**Pulumi**
Same idea as CDKTF but runs its own engine instead of Terraform.
Supports true async/await, direct output transforms, and stack
references instead of `remote_state`. State defaults to Pulumi Cloud.
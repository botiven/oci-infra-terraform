# OCI Free Tier Kubernetes Cluster
Deploy a (nearly) free Kubernetes cluster on Oracle Cloud Infrastructure (OCI) utilizing the free tier resources.

## Overview
This repository contains Infrastructure as Code (IaC) configurations for setting up a Kubernetes cluster on OCI's free tier resources. The setup includes all necessary components for running a Kubernetes cluster, including ingress configuration through Cloudflare Tunnels, monitoring using Prometheus and Grafana and Clickhouse deployment.

## Prerequisites
- Oracle Cloud Infrastructure (OCI) Account
  - Free tier eligible
  - Account must be verified
  - Credit card required for verification (won't be charged for free tier resources)
- Cloudflare Account
  - Free tier is sufficient
  - Cloudflare Tunnel access
- Registered domain name
  - Will be used for configuring ingress through Cloudflare Tunnels

## Cost Considerations
While this setup primarily uses free tier resources, there are some potential costs to be aware of:

### Free Components
- Kubernetes control plane
- Worker nodes (within free tier limits)
- Network resources (VCN, subnets, security lists)

### Paid Components
- Persistent volumes for ClickHouse deployment
  - Can be avoided if ClickHouse is not required
  - Costs vary based on volume size and type

## Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/botiven/oci-infra-terraform
   cd oci-kubernetes-cluster
   ```

2. Configure terraform variables - `terraform.tfvars`

3. Initialize the project:
   ```bash
   terraform init
   ```

4. Review and deploy the cluster:
   ```bash
   terraform plan    # Review the changes
   terraform apply   # Deploy the infrastructure
   ```

5. After deployment:
   Kubernetes configuration file will be generated in the project root directory

6. Traefik ingress will be using Cloudflare Tunnel and can be accessed at 			`https://kube.example.com` (replace `example.com` with domain configured in `terraform.tfvars`).

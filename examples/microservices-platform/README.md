# Microservices Platform on EKS

Production-ready Kubernetes platform with EKS.

## Architecture
- Amazon EKS cluster
- Multiple node groups
- RDS PostgreSQL
- IRSA for pod security
- Auto-scaling

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform apply

# Configure kubectl
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_id)

# Verify
kubectl get nodes
```

## Cost
~$557/month for dev environment

## Cleanup
```bash
terraform destroy
```

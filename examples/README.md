# Terraform AWS Examples

This directory contains complete, production-ready examples demonstrating how to use the Terraform modules to build real-world infrastructure on AWS.

## 📁 Available Examples

### 1. [Simple Web Application](./simple-web-app/)
**Complexity:** ⭐ Beginner | **Cost:** ~$100/month

A traditional three-tier web application with ALB, EC2, RDS, and S3.

### 2. [Microservices Platform on EKS](./microservices-platform/)
**Complexity:** ⭐⭐⭐ Advanced | **Cost:** ~$557/month (dev)

Modern microservices platform with EKS, multiple node groups, and IRSA.

### 3. [Data Processing Pipeline](./data-processing-pipeline/)
**Complexity:** ⭐⭐ Intermediate | **Cost:** ~$200-300/month

Automated data processing with auto-scaling processors and multi-stage S3 buckets.

## 🚀 Quick Start

1. Choose an example: `cd examples/simple-web-app/`
2. Configure: `cp terraform.tfvars.example terraform.tfvars`
3. Deploy: `terraform init && terraform apply`

## 📊 Comparison Matrix

| Feature | Simple Web App | Microservices | Data Pipeline |
|---------|----------------|---------------|---------------|
| Complexity | Low | High | Medium |
| Monthly Cost | ~$100 | ~$557+ | ~$200-300 |
| Containers | ❌ | ✅ (EKS) | ❌ |
| Auto Scaling | ✅ | ✅ | ✅ |
| Best For | Web Apps | Microservices | Batch Processing |

For detailed documentation, see individual example directories.

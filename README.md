# AWS EKS Secure Baseline (Terraform)

Production-oriented EKS baseline built with Terraform, implementing private control plane access, private worker nodes, IRSA (IAM Roles for Service Accounts), namespace isolation, default-deny networking, and OPA Gatekeeper policy enforcement.

This repository demonstrates a secure-by-default Kubernetes cluster foundation aligned with modern cloud security and platform engineering practices.

---

## Overview

This project provisions a hardened Amazon EKS cluster and applies foundational security controls at:

- Network layer
- Control plane layer
- Node layer
- Namespace layer
- Admission control layer
- Policy enforcement layer

The focus is not on application deployment, but on establishing a secure Kubernetes baseline suitable for production environments.

---

## Architecture

**Infrastructure Layer**
- Custom VPC
- Public and private subnets
- NAT gateway
- Tagged subnets for Kubernetes load balancing

**Cluster Layer**
- Amazon EKS cluster
- Private API endpoint access only
- Managed node group in private subnets
- OIDC provider enabled for IRSA

**Security Baseline**
- Restricted Pod Security Admission
- Dedicated secure namespace
- Default-deny NetworkPolicy
- OPA Gatekeeper installed via Helm
- Resource governance constraint (CPU & memory limits required)

---

## Security Design Principles

### 1. Private Control Plane
The EKS API endpoint is configured with:
- `endpoint_private_access = true`
- `endpoint_public_access  = false`

The control plane is not exposed publicly.

---

### 2. Private Worker Nodes
Managed node groups are deployed in private subnets.
Outbound access is provided via NAT.

Nodes are not directly internet-facing.

---

### 3. IAM Roles for Service Accounts (IRSA)

An OIDC provider is configured for the cluster, enabling:

- Fine-grained IAM permissions per Kubernetes ServiceAccount
- Elimination of node-wide IAM over-privileging
- Secure pod-level identity

This aligns with AWS-recommended Kubernetes identity patterns.

---

### 4. Namespace Security Baseline

A dedicated `secure-apps` namespace is created with:

- Pod Security Admission (`restricted` mode)
- Enforced least-privilege container settings

This prevents:
- Privileged containers
- Host networking
- Unsafe capabilities

---

### 5. Network Isolation

A default-deny NetworkPolicy is applied:

- Blocks all ingress and egress by default
- Enforces explicit communication rules
- Prevents lateral movement

---

### 6. Policy as Code (OPA Gatekeeper)

OPA Gatekeeper is installed via Helm.

A custom ConstraintTemplate and Constraint enforce:

- All Pods must define CPU limits
- All Pods must define memory limits

This ensures:
- Resource governance
- Controlled scheduling behavior
- Reduced risk of noisy neighbor issues

---

## Repository Structure

```
terraform/
├── modules/
│ ├── vpc/
│ ├── eks/
│ └── security/
│
└── environments/
└── prod/
```

The design follows a modular Terraform structure with environment separation.

---

## What This Repository Demonstrates

- Secure EKS provisioning with Terraform
- Network-aware Kubernetes architecture
- Private-by-default cluster posture
- IRSA implementation for workload identity
- Namespace-level isolation
- Policy-as-Code enforcement
- Cloud-native security controls aligned with DevSecOps practices

This repository represents a secure Kubernetes baseline, not a tutorial or lab environment.

---

## Intended Use

This baseline can serve as:

- A starting point for secure Kubernetes platforms
- A reference architecture for hardened EKS deployments
- A foundation for GitOps or CI/CD-based application delivery

---

## Author

Sebastian Silva C. – Cloud Engineer | Secure Infrastructure & Automation – Berlin, Germany

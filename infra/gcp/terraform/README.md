# OpenTofu / Terraform: GCP project + regional GKE

This stack creates a dedicated GCP project and a regional GKE cluster for the demo. Configuration is standard HCL; use the **[OpenTofu](https://opentofu.org/)** CLI (`tofu`) or **HashiCorp Terraform** 1.6+ (`terraform`) interchangeably.

## What it creates

- GCP project (and billing link)
- Required Google APIs
- Custom VPC + subnet with secondary ranges
- Regional GKE cluster (HA-oriented default)
- Autoscaling node pool

## Prerequisites

- `gcloud` installed and authenticated
- OpenTofu (`tofu`) or Terraform 1.6+
- Permission to create projects and attach billing
- Application Default Credentials (ADC) initialized for provider operations

## Usage

1. Authenticate for both CLI and ADC:

```bash
gcloud auth login
gcloud auth application-default login
```

2. From the repository root, copy variables file:

`cp ./infra/gcp/terraform/terraform.tfvars.example ./infra/gcp/terraform/terraform.tfvars`

3. Edit `infra/gcp/terraform/terraform.tfvars` values.
4. Initialize and apply (OpenTofu):

```bash
cd ./infra/gcp/terraform
tofu init
tofu plan -out tfplan
tofu apply tfplan
```

If you use HashiCorp Terraform, run the same steps with `terraform` instead of `tofu`.

## After apply

1. Fetch kubeconfig:

```bash
gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>
```

2. Deploy ingress-nginx and record the external IP.
3. In your DNS provider, add A records for:
   - `demo.gitops-promoter.dev`
   - `promoter-webhook.gitops-promoter.dev`
   - `grafana.gitops-promoter.dev`
4. Continue with Argo CD bootstrap from `apps/root-app.yaml`.

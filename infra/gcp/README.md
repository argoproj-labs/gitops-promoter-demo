# GCP Bootstrap Inputs

Use this file to pin environment-specific values before provisioning.

## Required values

- `PROJECT_ID`: Google Cloud project ID for the demo
- `PROJECT_NAME`: display name for the project
- `BILLING_ACCOUNT`: billing account ID to link to the project
- `REGION`: GKE region, for example `us-central1`
- `CLUSTER_NAME`: for example `gitops-promoter-demo`
- `BASE_DOMAIN`: `gitops-promoter.dev`

## DNS model

- DNS stays with your DNS provider (Terraform does not create a Cloud DNS zone in this demo).
- After `ingress-nginx` has an external IP, print the address to use for A records:

  ```bash
  ./get-ingress-lb-ip.sh
  ```

  Run from `infra/gcp`, with `kubectl` already configured for the cluster.

- Create/maintain A records in your DNS provider for:
  - `demo.gitops-promoter.dev`
  - `promoter-webhook.gitops-promoter.dev`
  - `grafana.gitops-promoter.dev`
- Point them at that ingress load balancer IP.

## IAM and API prerequisites

Enable APIs at minimum:

- Cloud Resource Manager API
- Cloud Billing API
- Kubernetes Engine API
- Compute Engine API
- IAM API
- Service Account Credentials API

## Bootstrap checks

Before first `terraform apply`, verify:

1. `gcloud auth list` shows your account.
2. `gcloud beta billing accounts list` returns the target billing account.
3. Your account can create projects and attach billing.
4. `gitops-promoter.dev` DNS records can be edited in your DNS provider.

## Notes

- Terraform files live in `infra/gcp/terraform`.
- Start with regional GKE for higher availability, then downscale later if needed.

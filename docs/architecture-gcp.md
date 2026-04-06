# GCP Architecture (Initial)

This document captures the cloud assumptions for the demo instance on Google Cloud.

## Platform choices

- Kubernetes: GKE Standard, regional cluster for higher availability
- Provisioning: OpenTofu or Terraform (project, APIs, network, cluster)
- DNS: Provider-managed DNS zone for demo hostnames
- TLS: cert-manager using ACME HTTP-01 via ingress-nginx
- Ingress: ingress-nginx (to stay close to the existing plan), with cert-manager **CA injection** for the ingress admission `ValidatingWebhookConfiguration` so `clientConfig.caBundle` stays populated under GitOps
- Secrets at rest in Git: Sealed Secrets (including the Argo CD Git webhook HMAC via a companion `Secret` and indirection — see [SETUP.md](../SETUP.md) §8)
- Workload identity: GKE Workload Identity for in-cluster controllers

## Public endpoints

- `demo.gitops-promoter.dev`: Argo CD UI and API (embedded Dex with [GitHub OAuth](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#configuring-github-oauth2); **`/api/dex/callback`** for SSO; **`/api/webhook`** for [Git webhooks](https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/) when configured)
- `promoter-webhook.gitops-promoter.dev`: GitOps Promoter webhook receiver (separate from Argo CD’s Git webhook; **no HMAC secret verification** in Promoter today — see [SETUP.md](../SETUP.md) §12.1)
- `grafana.gitops-promoter.dev`: public read-only dashboard

Per-**Ingress** nginx rate limits (**`limit-rps` / `limit-burst-multiplier`**) are set in **`charts/argocd`** and **`charts/monitoring`** for typical browser use. [Cloud Armor](https://cloud.google.com/armor/docs/cloud-armor-overview) needs an HTTP(S) load balancer in front of the cluster, not the default NLB → nginx path.

## Open implementation decisions

1. Keep `ingress-nginx` or move to GKE Gateway API later.
2. Keep Sealed Secrets only, or blend with Secret Manager CSI later.
3. Initial node machine type and autoscaling min/max bounds.

## Required inputs before first apply

- GCP billing account ID (existing; OpenTofu links the **new** project to it)
- Desired GCP project ID and display name for the project this stack **creates** (`terraform.tfvars`)
- Region and node sizing: defaults in `infra/gcp/terraform/main.tf` locals (override there if needed)
- Domain registrar API strategy (manual DNS records vs API automation)
- GitHub org/repo names and admin access

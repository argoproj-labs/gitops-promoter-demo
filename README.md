# GitOps Promoter demo (GCP)

Public-style demo that runs **[GitOps Promoter](https://gitops-promoter.readthedocs.io/)** on **GKE**: promotions across hydrated **Argo CD** environments (**`env/dev` → `env/e2e` → `env/prd`**), commit statuses, and a small **guestbook** app rendered by the [source hydrator](https://argo-cd.readthedocs.io/en/stable/user-guide/source-hydrator/).

**Docs in this repo**

| Doc | Audience |
|-----|----------|
| **[SETUP.md](SETUP.md)** | First-time cluster bring-up, Terraform, Argo bootstrap, secrets, DNS, monitoring, Promoter GitHub App |
| **[DEBUGGING.md](DEBUGGING.md)** | Auth issues, Prometheus/Grafana scrape gaps, Dex/Grafana OAuth, churn script, timer checks, webhooks |

## Stack (high level)

- **GKE** + **Terraform** (`infra/gcp/terraform/`)
- **Argo CD** (App-of-Apps, single-source `Application`s; guestbook envs use **source hydration**)
- **cert-manager** + **ingress-nginx** for TLS
- **Sealed Secrets** for credentials in Git
- **GitOps Promoter** + **`promoter-config/`** CRs
- **kube-prometheus-stack** (optional path via **`charts/monitoring/`**) for Prometheus / Grafana

## What gets installed

Child **Application**s are defined as a Helm chart under **`charts/apps/`** (one **`repoURL`** in **`values.yaml`**; bootstrap **`apps/root-app.yaml`** points at that chart). They install Argo CD (Dex + GitHub OAuth wiring in values), cert-manager, ingress-nginx, Sealed Secrets, monitoring, GitOps Promoter, **`demo-config`**, guestbook envs, demo churn **CronJob**, etc. Exact versions: [SETUP.md — Version pins](SETUP.md#version-pins-currently-used).

## Repository layout (short)

| Path | Role |
|------|------|
| **`apps/`** | Bootstrap **`root-app`** only |
| **`charts/apps/`** | Helm chart: all other Argo CD **`Application`**s (**`repoURL`** in **`values.yaml`**) |
| **`demo-apps/guestbook/`** | In-tree Helm chart; hydrator writes rendered trees to **`hydrated/guestbook-*`** on **`env/<env>-next`** |
| **`charts/`** | Umbrella charts: **apps** (Argo child apps), **argocd**, **gitops-promoter**, **monitoring** (+ sealed templates) |
| **`manifests/demo-churn/`** | CronJob that bumps **`demoChurn.lastBumped`** via GitHub API |
| **`promoter-config/`** | `PromotionStrategy`, `GitRepository`, `ScmProvider`, commit-status controllers |
| **`infra/gcp/`** | Terraform, helper scripts |
| **`docs/`** | Extra architecture notes |

Conventions (GitOps-first, sync options, hydrator branches): [SETUP.md — Conventions](SETUP.md#conventions).

## Forking

Replace GitHub URLs, hostnames, org/team names, and seal your own secrets — full file list in [SETUP.md §2](SETUP.md#2-customize-repository-and-domain-references).

## License / upstream

Operator and behavior are defined by **argoproj-labs** projects; this tree is a demo wiring. See upstream docs for APIs and RBAC details.

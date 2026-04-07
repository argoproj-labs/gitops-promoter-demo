# GitOps Promoter Demo

Live demo on hosted Argo CD (GitOps Promoter extension):

- **GitHub path** (control repo + guestbook + churn): [Open `promoter-config-github` — `demo-github` PromotionStrategy](https://demo.gitops-promoter.dev/applications/argocd/promoter-config-github?resource=&view=GitOps+Promoter&promotionstrategy=gitops-promoter%2Fdemo-github)
- **GitLab path** (guestbook-only GitLab project, parallel flow): [Open `promoter-config-gitlab` — `demo-gitlab` PromotionStrategy](https://demo.gitops-promoter.dev/applications/argocd/promoter-config-gitlab?resource=&view=GitOps+Promoter&promotionstrategy=gitops-promoter%2Fdemo-gitlab)

You can use those views read-only without signing in. GitHub sign-in is for maintainers who need admin in Argo CD.

---

This repository is a hands-on reference for [GitOps Promoter](https://gitops-promoter.readthedocs.io/): moving changes through environments with Git, commit statuses, and Kubernetes APIs, wired here to Argo CD and a small guestbook workload on GKE.

## What GitOps Promoter does (here)

You describe promotion rules under `promoter-config-github/` and `promoter-config-gitlab/`—for example a `PromotionStrategy` (environment order, auto-merge, which commit statuses must pass) together with `ScmProvider` and `GitRepository`. Controllers such as Argo CD health and a timer write status checks back to Git; `activeCommitStatuses` and `promoter-previous-environment` gate each step ([gating](https://gitops-promoter.readthedocs.io/en/latest/gating-promotions/)).

In this demo, Argo CD’s [source hydrator](https://argo-cd.readthedocs.io/en/stable/user-guide/source-hydrator/) renders manifests into `hydrated/guestbook-*` on branches such as `env/dev-next`, `env/e2e-next`, and `env/prd-next`. GitOps Promoter opens and merges the pull requests that promote those changes through `env/dev`, `env/e2e`, and `env/prd` when your rules allow. What merges is rendered YAML—the same material Argo syncs.

You may have heard that using a branch per environment is a GitOps anti-pattern. That warning is about teams manually maintaining divergent env branches. In this model you evolve a single DRY configuration; the environment branches carry generated output that GitOps Promoter and the hydrator keep up to date, which is a different workflow. See [Does GitOps Promoter use branches for environments?](https://gitops-promoter.readthedocs.io/en/latest/faqs/#does-gitops-promoter-use-branches-for-environments) in the project FAQ.

On your own cluster, the GitOps Promoter Argo CD extension surfaces strategies and related resources (see the upstream integration docs).

## How to use this repository

| If you want to… | Start here |
|-----------------|------------|
| Learn APIs, controllers, and concepts in depth | [GitOps Promoter documentation](https://gitops-promoter.readthedocs.io/) |
| Provision this demo (GKE, DNS, TLS, secrets, monitoring, GitHub apps) | [SETUP.md](SETUP.md) |
| Troubleshoot auth, metrics, OAuth, webhooks, churn | [DEBUGGING.md](DEBUGGING.md) |
| Skim GCP-oriented architecture | [docs/architecture-gcp.md](docs/architecture-gcp.md) |
| Open Grafana (metrics / dashboards) | [Grafana](https://grafana.gitops-promoter.dev) |

Forking: replace GitHub URLs, hostnames, org/team names, and seal your own secrets—see [SETUP.md §2](SETUP.md#2-customize-repository-and-domain-references).

Version pins for Helm charts and images: [SETUP.md — Version pins](SETUP.md#version-pins-currently-used).

## What gets installed (brief)

The App-of-Apps entrypoint `apps/root-app.yaml` installs the Helm chart in `charts/apps/`, which declares child Applications for Argo CD, cert-manager, ingress-nginx, Sealed Secrets, monitoring, GitOps Promoter, guestbook environments, the demo churn job, and more. Umbrella values live under `charts/`. Layout and GitOps conventions are in [SETUP.md — Repository layout](SETUP.md#repository-layout) and [Conventions](SETUP.md#conventions).

## License / upstream

Behavior and CRDs come from argoproj-labs projects; this tree is example wiring only. See upstream docs for APIs, RBAC, and production hardening.

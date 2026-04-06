# GitOps Promoter Demo

**Live demo:** [**Open the GitOps Promoter view in Argo CD**](https://demo.gitops-promoter.dev/applications/argocd/promoter-config?resource=&view=GitOps+Promoter&promotionstrategy=gitops-promoter%2Fdemo) (hosted UI with the Promoter extension).

Opens the **`demo`** `PromotionStrategy` in the **`promoter-config`** Application. The UI is readable without signing in; GitHub login is for maintainers (see [SETUP.md](SETUP.md)).

---

This repository is a **hands-on reference** for understanding **[GitOps Promoter](https://gitops-promoter.readthedocs.io/)**: how it moves changes through environments using Git, commit statuses, and Kubernetes custom resources—here wired to **Argo CD** and a small **guestbook** app on **GKE**.

## What GitOps Promoter does (here)

Advice to avoid **Git branches per environment** usually targets workflows where people **manually** maintain divergent env branches. GitOps Promoter instead keeps **one DRY branch** for the sources you change; **hydrated** manifests for each environment sit on **separate branches that GitOps Promoter and your hydrator keep up to date**, which is a different experience than the anti-pattern (see **[Does GitOps Promoter use branches for environments?](https://gitops-promoter.readthedocs.io/en/latest/faqs/#does-gitops-promoter-use-branches-for-environments)**).

In this demo, Argo CD’s **[source hydrator](https://argo-cd.readthedocs.io/en/stable/user-guide/source-hydrator/)** writes `hydrated/guestbook-*` onto `env/<env>-next`, and GitOps Promoter merges forward through **`env/dev` → `env/e2e` → `env/prd`** when gates pass—you are not expected to treat those branches like hand-curated env copies.

You describe that promotion behavior in **`promoter-config/`** with resources such as **`PromotionStrategy`** (order of environments, auto-merge, which commit statuses must be green) and **`ScmProvider`** / **`GitRepository`**. **Commit status controllers** (for example **Argo CD health** and a **timer**) write status checks back to Git; the strategy’s **`activeCommitStatuses`** and **`promoter-previous-environment`** gate each step ([gating](https://gitops-promoter.readthedocs.io/en/latest/gating-promotions/)). Promotions move **rendered** manifests so what merges is what the cluster is meant to sync.

On your own cluster, the same **GitOps Promoter Argo CD extension** surfaces strategies and related objects (see upstream docs for the extension).

## How to use this repository

| If you want to… | Start here |
|-----------------|------------|
| Learn APIs, controllers, and concepts in depth | **[GitOps Promoter documentation](https://gitops-promoter.readthedocs.io/)** |
| **Provision** this demo (GKE, DNS, TLS, secrets, monitoring, GitHub apps) | **[SETUP.md](SETUP.md)** |
| **Troubleshoot** auth, metrics, OAuth, webhooks, churn | **[DEBUGGING.md](DEBUGGING.md)** |
| Skim GCP-oriented architecture | **[docs/architecture-gcp.md](docs/architecture-gcp.md)** |

**Forking:** replace GitHub URLs, hostnames, org/team names, and seal your own secrets—see [SETUP.md §2](SETUP.md#2-customize-repository-and-domain-references).

**Version pins** for Helm charts and images: [SETUP.md — Version pins](SETUP.md#version-pins-currently-used).

## What gets installed (brief)

Argo CD’s **App-of-Apps** bootstrap (`apps/root-app.yaml`) installs a Helm chart under **`charts/apps/`** that declares child **Applications** for Argo CD, cert-manager, ingress-nginx, Sealed Secrets, monitoring, GitOps Promoter, guestbook environments, demo churn, and more. Umbrella values live under **`charts/`**; exact layout and GitOps conventions are documented in **[SETUP.md — Repository layout](SETUP.md#repository-layout)** and **[Conventions](SETUP.md#conventions)**.

## License / upstream

Behavior and CRDs come from **argoproj-labs** projects; this tree is example wiring only. See upstream docs for APIs, RBAC, and production hardening.

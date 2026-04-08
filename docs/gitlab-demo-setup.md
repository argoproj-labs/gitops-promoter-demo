# GitLab parallel demo (guestbook-only GitLab project)

The control plane stays in **this GitHub repo**. The GitLab project [gitops-promoter-group/gitops-promoter-project](https://gitlab.com/gitops-promoter-group/gitops-promoter-project) holds **only** the guestbook chart; **env/**\* promotion branches are created automatically when Argo CD’s source hydrator syncs the GitLab guestbook Applications.

## 1. Seed GitLab from `gitlab-seed/`

From your laptop (requires Git and a GitLab credential):

```bash
cd gitlab-seed
git init
git checkout -b main
git remote add origin https://gitlab.com/gitops-promoter-group/gitops-promoter-project.git
git add demo-apps
git commit -m "chore: seed guestbook chart for GitOps Promoter demo"
git push -u origin main
```

**Cleanup (required for this monorepo):** `git init` created **`gitlab-seed/.git`**. The outer repo will otherwise record **`gitlab-seed`** as a nested repository (gitlink)—clones will not get the chart files, and **`git status`** in the parent will warn. From the **repository root**:

```bash
rm -rf gitlab-seed/.git
```

After that, commit **`gitlab-seed/demo-apps/`** as normal paths in the GitHub control-plane repo (optional but keeps the seed in sync with what you pushed). If you truly want a submodule instead, use **`git submodule add`** and do **not** run the **`rm`** above.

If you already staged **`gitlab-seed`** while **`gitlab-seed/.git`** existed, Git indexed a gitlink. Fix:

```bash
git rm --cached -r gitlab-seed
rm -rf gitlab-seed/.git
git add gitlab-seed
```

## 2. Project access token (Free tier)

In GitLab: **Project → Settings → Access tokens**

- **Role: Maintainer** (not Developer). The Argo CD source hydrator and the **`demo-churn-gitlab`** CronJob **commit directly to `main`** (no merge request). On a typical project, **`main` is protected** and only **Maintainer** (or higher) may push there; a **Developer** token often gets **`403 Forbidden — You are not allowed to push into this branch`** from the API even with **`write_repository`**.
- Scopes: **`api`**, **`write_repository`**
- Create token and store it securely.

If you must use a **Developer** token instead, change **protected branch** rules so that role can push to **`main`**, or use a different branch and update **`GITLAB_DEFAULT_BRANCH`** / hydrator target branches accordingly.

Use it in three places below (you may use one token for all three, or separate tokens with the same scopes and role).

### Rotate / re-seal one token everywhere

From the **repository root**, with **`kubectl`** pointed at the cluster that runs **Sealed Secrets** (`sealed-secrets` in **`kube-system`**) and **`kubeseal`** installed:

```bash
./scripts/reseal-gitlab-token.sh
```

You will be prompted to paste the token (input is hidden). The script rewrites the three **SealedSecret** files below. Override the guestbook repo URL if needed: **`GUESTBOOK_GITLAB_REPO_URL`**.

## 3. Secret `gitlab-scm-credentials` (namespace `gitops-promoter`)

GitOps Promoter reads key **`token`**.

```bash
kubectl create secret generic gitlab-scm-credentials -n gitops-promoter \
  --from-literal=token='YOUR_GITLAB_PROJECT_ACCESS_TOKEN' \
  --dry-run=client -o yaml \
  | kubeseal \
      --controller-name sealed-secrets \
      --controller-namespace kube-system \
      -o yaml -n gitops-promoter \
      -w charts/gitops-promoter/templates/gitlab-scm-credentials.sealed.yaml
```

The Bitnami chart in **`charts/sealed-secrets`** uses Service **`sealed-secrets`** in **`kube-system`** (not `kubeseal`’s default **`sealed-secrets-controller`**); use the same **`kubeseal`** flags as in [SETUP.md](SETUP.md#git-webhooks-sync-soon-after-you-push) (**§8**). Commit the sealed file.

## 4. Argo CD: hydrator push (GitLab HTTPS)

The guestbook chart repo is **public**, so Argo CD can **clone** over HTTPS **without** a `repository` Secret. The [**source hydrator**](https://argo-cd.readthedocs.io/en/stable/user-guide/source-hydrator/) still needs a **`repository-write`** Secret so it can **push** rendered manifests to **`env/*-next`** on  
`https://gitlab.com/gitops-promoter-group/gitops-promoter-project.git`  
(the same URL as **`charts/apps/values.yaml`** → **`guestbookGitLabRepoURL`**; keep them identical).

Per [declarative repos](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repositories), the Secret must include **`type`**, **`url`**, **`username`**, **`password`** (the PAT). GitLab accepts several usernames for HTTPS + token; **`oauth2`** usually works—if not, try your GitLab username or see GitLab’s [project access token](https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html) docs.

From the **repository root** (same **`kubectl label`** / **`kubeseal`** pattern as the GitHub hydrator write secret in [SETUP.md](SETUP.md#source-hydrator-credentials-push-for-in-tree-guestbook)):

```bash
kubectl create secret generic argocd-repo-gitlab-guestbook-write -n argocd \
  --from-literal=type=git \
  --from-literal=url='https://gitlab.com/gitops-promoter-group/gitops-promoter-project.git' \
  --from-literal=username=oauth2 \
  --from-literal=password='YOUR_GITLAB_PROJECT_ACCESS_TOKEN' \
  --dry-run=client -o yaml \
  | kubectl label --local --dry-run=client -f - argocd.argoproj.io/secret-type=repository-write -o yaml \
  | kubectl label --local --dry-run=client -f - app.kubernetes.io/part-of=argocd -o yaml \
  | kubeseal \
      --controller-name sealed-secrets \
      --controller-namespace kube-system \
      -o yaml -n argocd \
      -w charts/argocd/templates/argocd-repo-gitlab-guestbook-write.sealed.yaml
```

Commit **`charts/argocd/templates/argocd-repo-gitlab-guestbook-write.sealed.yaml`**. It is picked up by the **`Application/argocd`** umbrella the same way as **`argocd-repo-gitops-promoter-write.sealed.yaml`**.

If the repo were **private**, you would add a second Secret with **`argocd.argoproj.io/secret-type: repository`** (read/clone) for the same URL prefix—seal it the same way but without the **`repository-write`** label and with the same **`username`** / **`password`** keys.

## 5. Secret `gitlab-demo-churn-credentials` (namespace `argocd`)

The GitLab churn CronJob (**`demo-churn-gitlab`**, under **`manifests/demo-churn/gitlab/`**, synced by **`Application/demo-churn`**) needs key **`token`** (same project access token is fine).

Seal it into **`charts/argocd/templates/`** so the **`Application/argocd`** umbrella applies it with the other **SealedSecret**s (**`argocd-github-webhook`**, **`argocd-repo-gitops-promoter-write`**, **`gitlab`** repo write, and so on)—no separate Application.

```bash
kubectl create secret generic gitlab-demo-churn-credentials -n argocd \
  --from-literal=token='YOUR_GITLAB_PROJECT_ACCESS_TOKEN' \
  --dry-run=client -o yaml \
  | kubectl label --local --dry-run=client -f - app.kubernetes.io/part-of=argocd -o yaml \
  | kubeseal \
      --controller-name sealed-secrets \
      --controller-namespace kube-system \
      -o yaml -n argocd \
      -w charts/argocd/templates/gitlab-demo-churn-credentials.sealed.yaml
```

Commit **`charts/argocd/templates/gitlab-demo-churn-credentials.sealed.yaml`** and sync **`Application/argocd`** (or let the App-of-Apps reconcile it).

## 6. Argo CD: GitLab → webhook (fast refresh)

By default Argo CD **polls** Git about every **three minutes**. To refresh Applications as soon as the GitLab guestbook repo changes, send **project webhooks** to Argo CD’s **`/api/webhook`** endpoint. This is **separate** from **GitOps Promoter**’s receiver (this demo uses another hostname for Promoter—see [SETUP.md](../SETUP.md) **§12.1** / **§8** “Not the GitOps Promoter webhook”).

Upstream: [Argo CD — Git webhook configuration](https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/) (GitLab uses **`webhook.gitlab.secret`** in **`argocd-secret`**).

### 6.1 Create the webhook in GitLab

In the **guestbook GitLab project**: **Settings → Webhooks** (or **Integrations**):

| Field | Value |
| --- | --- |
| **URL** | `https://<your-argocd-host>/api/webhook` (this demo: **`https://demo.gitops-promoter.dev/api/webhook`**) |
| **Secret token** | A long random string (same value you will seal for Argo CD below) |
| **Trigger** | Enable **Push events** (repository updates). You can disable everything else unless you need it. |

Save the webhook. **SSL verification** should stay on if Argo CD presents a valid cert (e.g. cert-manager on the ingress).

### 6.2 Configure Argo CD with the same secret

Argo CD verifies GitLab’s **`X-Gitlab-Token`** header against **`webhook.gitlab.secret`**. **argo-helm** maps that from **`configs.secret.gitlabSecret`**.

**In this repo, Helm values are already wired** the same way as the GitHub webhook: **`charts/argocd/values.yaml`** sets **`gitlabSecret: "$argocd-gitlab-webhook:gitlabWebhookSecret"`** (companion **Secret** name + key). You do **not** edit values for a normal setup—only add the **cluster-specific** sealed manifest (like **`argocd-github-webhook.sealed.yaml`** in [SETUP.md §8](../SETUP.md#git-webhooks-sync-soon-after-you-push)).

**Seal** **`argocd-gitlab-webhook`** in **`argocd`** with label **`app.kubernetes.io/part-of: argocd`** and data key **`gitlabWebhookSecret`** (the same string as GitLab’s **Secret token**):

```bash
# From repository root; replace YOUR_GITLAB_WEBHOOK_SECRET with the token you set in GitLab.
kubectl create secret generic argocd-gitlab-webhook -n argocd \
  --from-literal=gitlabWebhookSecret='YOUR_GITLAB_WEBHOOK_SECRET' \
  --dry-run=client -o yaml \
  | kubectl label --local --dry-run=client -f - app.kubernetes.io/part-of=argocd -o yaml \
  | kubeseal \
      --controller-name sealed-secrets \
      --controller-namespace kube-system \
      -o yaml -n argocd \
      -w charts/argocd/templates/argocd-gitlab-webhook.sealed.yaml
```

Commit **`charts/argocd/templates/argocd-gitlab-webhook.sealed.yaml`** and sync **`Application/argocd`**.

Until that **SealedSecret** exists and is synced, Argo CD cannot resolve the token and GitLab deliveries may fail verification. If you skip sealing entirely, GitLab can still call **`/api/webhook`**, but Argo CD cannot verify the caller; for a **public** Argo URL, sealing the secret is **strongly recommended** ([upstream](https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/#2-configure-argo-cd-with-the-webhook-secret-optional)).

### 6.3 Verify

Push a trivial commit to the GitLab guestbook repo. In Argo CD, Applications that use that repo should move to **Refreshing** quickly. In GitLab, open the webhook’s **Recent deliveries** and confirm **`HTTP 200`**.

## 7. Sync order

After merge + Argo refresh:

1. `promoter-config-gitlab` → `ScmProvider` / `GitRepository` / `PromotionStrategy` **demo-gitlab** (fails until `gitlab-scm-credentials` exists).
2. Guestbook GitLab apps → need **`argocd-repo-gitlab-guestbook-write`** (public clone needs no read Secret).
3. **`Application/demo-churn`** (GitLab half) → needs **`gitlab-demo-churn-credentials`** and the seeded file on **`main`**.

## 8. Project ID

`promoter-config-gitlab/git-repository.yaml` uses **`projectId: 81067674`**. If you recreate the project, update it (e.g. `curl -s https://gitlab.com/api/v4/projects/<path_encoded>`).

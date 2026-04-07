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

- Role: **Developer** (or Maintainer)
- Scopes: **`api`**, **`write_repository`**
- Create token and store it securely.

Use it in three places below (you may use one token for all three, or separate tokens with the same scopes).

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

## 6. Sync order

After merge + Argo refresh:

1. `promoter-config-gitlab` → `ScmProvider` / `GitRepository` / `PromotionStrategy` **demo-gitlab** (fails until `gitlab-scm-credentials` exists).
2. Guestbook GitLab apps → need **`argocd-repo-gitlab-guestbook-write`** (public clone needs no read Secret).
3. **`Application/demo-churn`** (GitLab half) → needs **`gitlab-demo-churn-credentials`** and the seeded file on **`main`**.

## 7. Project ID

`promoter-config-gitlab/git-repository.yaml` uses **`projectId: 81067674`**. If you recreate the project, update it (e.g. `curl -s https://gitlab.com/api/v4/projects/<path_encoded>`).

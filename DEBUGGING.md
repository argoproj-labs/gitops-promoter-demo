# Debugging

Common problems while bringing up the demo from [SETUP.md](SETUP.md). Commands assume a default install (namespaces **`argocd`**, **`monitoring`**, **`gitops-promoter`**).

---

## kubectl / GKE authentication

**Symptoms:** `Unable to connect to the server`, `Failed to retrieve access token`, or `gke-gcloud-auth-plugin` errors.

**Checks:**

- Run `gcloud auth login` and `gcloud container clusters get-credentials …` (see [SETUP.md §6](SETUP.md#6-fetch-kubeconfig-and-verify-kubectl)).
- Install the plugin: `gcloud components install gke-gcloud-auth-plugin`.

---

## Argo CD sync status `Unknown`

Right after bootstrap or a large first push, the UI can show **Unknown** briefly while the repo is fetched. Wait and refresh. If it persists, check `kubectl -n argocd logs deployment/argocd-application-controller` and that **`Application`** `spec.source` URLs and branches exist.

---

## Argo CD Dex: “login failed”

1. **Callback URL** on the GitHub OAuth app must be exactly `https://<argocd-host>/api/dex/callback` (no trailing slash; **https** if the UI is served over TLS).
2. **`Secret/argocd-dex-github`** in **`argocd`**: keys **`clientId`** / **`clientSecret`** (camelCase), label **`app.kubernetes.io/part-of: argocd`**.
3. **Org approval:** GitHub must allow the OAuth app for your org or Dex cannot read teams (`application not authorized to read org data` in Dex logs).
4. Logs:

```bash
kubectl -n argocd logs deploy/argocd-dex-server --tail=80
kubectl -n argocd logs deploy/argocd-server --tail=80
```

---

## Grafana GitHub OAuth: `redirect_uri` not associated with this application

Grafana needs a **separate** GitHub OAuth app from Argo Dex (one callback URL per OAuth app). The Grafana app’s callback must be `https://<grafana-host>/login/github`. If the browser error shows a **`client_id`** tied to the Dex app, create or fix the Grafana-only app and re-seal **`charts/monitoring/templates/grafana-github-oauth.sealed.yaml`**, then restart Grafana if env vars were cached.

---

## Prometheus CR stuck “waiting for healthy”

**Cause:** The **Prometheus Operator** pod can become **Ready** before **`prometheuses.monitoring.coreos.com`** CRDs exist. At startup it logs `resource "prometheuses" … not installed` and **never** enables those controllers until the process restarts. You get **`Prometheus`** / **`Alertmanager`** CRs with **empty `status`** and **no** Prometheus **StatefulSet**.

**Fix:**

```bash
kubectl -n monitoring rollout restart deploy/monitoring-kube-prometheus-operator
kubectl -n monitoring get sts,pods -l app.kubernetes.io/name=prometheus
```

---

## Grafana or Prometheus: no GitOps Promoter metrics

**Cause:** Upstream **`gitops-promoter`** Helm chart **0.5.1** ships a **`ServiceMonitor`** whose selector does not match the metrics **Service** labels (`app.kubernetes.io/name` **`gitops-promoter`** vs **`service`**). Prometheus **drops** those targets after relabeling, so **`git_operations_*`** never appears.

**In this repo:** **`gitops-promoter.prometheus.enable: false`** and a corrected **`ServiceMonitor`** in **`charts/gitops-promoter/templates/controller-metrics-servicemonitor.yaml`**. Upstream tracking: [gitops-promoter-helm#74](https://github.com/argoproj-labs/gitops-promoter-helm/issues/74).

**Also:** Prometheus must discover **`ServiceMonitor`**s in **`gitops-promoter`** — **`charts/monitoring/values.yaml`** sets **`serviceMonitorSelectorNilUsesHelmValues: false`** and **`serviceMonitorSelector: {}`**.

**Sanity checks:** In Grafana **Explore → Prometheus**, try `up{namespace="gitops-promoter"}` or `git_operations_total`. If a new **`ServiceMonitor`** is slow to appear, restart the operator (same as above).

---

## Demo churn CronJob corrupts `demoChurn.lastBumped`

**Cause:** The replacement string used `rf"\1{iso}\2"`. In `re.sub`, **`\1` followed by digits** is parsed as an **octal** escape (e.g. `\120` → **`P`**), not “group 1 + timestamp”.

**Fix (in repo):** `rf"\g<1>{iso}\g<2>"` in **`manifests/demo-churn/configmap-churn.yaml`**. Repair **`demo-apps/guestbook/values.yaml`** so **`demoChurn.lastBumped`** is again a single quoted ISO line; sync the updated **ConfigMap** before the next job run.

---

## Timer commit status missing for `env/dev` (or another env)

**Cause:** **`PromotionStrategy`** lists **`timer`** in **`activeCommitStatuses`**, but **`TimedCommitStatus.spec.environments`** omitted a branch. The timed controller only creates GitHub checks for branches it knows about.

**Fix:** List **every** gated branch under **`TimedCommitStatus`** with the same names as **`PromotionStrategy.spec.environments[].branch`** (see **`promoter-config/commit-statuses/timed-commit-status.yaml`**).

---

## Ingress admission webhook / `cert-manager` CA

If new **`Ingress`** objects fail validation, check that **cert-manager** injected the CA into **`ValidatingWebhookConfiguration/ingress-nginx-admission`**:

```bash
kubectl get validatingwebhookconfiguration ingress-nginx-admission \
  -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | wc -c
```

A **zero** length means the bundle is missing; confirm **`ingress-nginx`** and **cert-manager** Applications are synced and healthy (see [SETUP.md §11](SETUP.md#11-verify-bootstrap-components)).

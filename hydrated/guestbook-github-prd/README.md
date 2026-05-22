# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout fe70bf265f48a5cbb4606f9d25035c562a304d7b
helm template . --name-template guestbook-github-prd --namespace guestbook-github-prd --values ./demo-apps/guestbook/env/prd/values.yaml --include-crds
```

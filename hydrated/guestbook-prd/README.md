# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout b124f635d2ed905b4eadcd070dbec4632eb51085
helm template . --name-template guestbook-prd --namespace guestbook-prd --values ./demo-apps/guestbook/env/prd/values.yaml --include-crds
```

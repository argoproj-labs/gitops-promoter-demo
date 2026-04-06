# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 96c658ecd77e3fa2845ca0d94a0d0d88ccb3430a
helm template . --name-template guestbook-prd --namespace guestbook-prd --values ./demo-apps/guestbook/env/prd/values.yaml --include-crds
```

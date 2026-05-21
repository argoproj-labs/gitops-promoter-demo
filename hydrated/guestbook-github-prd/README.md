# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout f2a50b3cfac340fa8beeaa6b50d612e3072dc4dc
helm template . --name-template guestbook-github-prd --namespace guestbook-github-prd --values ./demo-apps/guestbook/env/prd/values.yaml --include-crds
```

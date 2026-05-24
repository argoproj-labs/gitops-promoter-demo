# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout cb9fe627af20170bb6a28b8b23370dfc061a19aa
helm template . --name-template guestbook-github-prd --namespace guestbook-github-prd --values ./demo-apps/guestbook/env/prd/values.yaml --include-crds
```

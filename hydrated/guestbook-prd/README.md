# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 342597dd9ac83622b869928b88b838097e51422a
helm template . --name-template guestbook-prd --namespace guestbook-prd --values ./demo-apps/guestbook/env/prd/values.yaml --include-crds
```

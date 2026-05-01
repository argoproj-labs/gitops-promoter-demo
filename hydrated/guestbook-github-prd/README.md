# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 2497469547e90949f6085819994e2a19f26cc169
helm template . --name-template guestbook-github-prd --namespace guestbook-github-prd --values ./demo-apps/guestbook/env/prd/values.yaml --include-crds
```

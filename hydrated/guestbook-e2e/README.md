# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 284d2f8a53dc73adf0a0cc658b696574c3ead785
helm template . --name-template guestbook-e2e --namespace guestbook-e2e --values ./demo-apps/guestbook/env/e2e/values.yaml --include-crds
```

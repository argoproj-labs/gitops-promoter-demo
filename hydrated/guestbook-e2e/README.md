# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout b1eb3c838df37b9eaac168d55b155b13c719ada3
helm template . --name-template guestbook-e2e --namespace guestbook-e2e --values ./demo-apps/guestbook/env/e2e/values.yaml --include-crds
```

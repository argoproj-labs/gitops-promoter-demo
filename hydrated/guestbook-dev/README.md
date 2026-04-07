# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 7974ac6114c2f00f6da5331fbf8d9c6c071875e3
helm template . --name-template guestbook-dev --namespace guestbook-dev --values ./demo-apps/guestbook/env/dev/values.yaml --include-crds
```

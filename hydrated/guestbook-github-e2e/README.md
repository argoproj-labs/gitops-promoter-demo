# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 44253a72690d1c7657e4aad5c64b8cdbc17af15a
helm template . --name-template guestbook-github-e2e --namespace guestbook-github-e2e --values ./demo-apps/guestbook/env/e2e/values.yaml --include-crds
```

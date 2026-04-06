# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 5d6d7b57d9778bd2a88529d952acf6e5a4a7ad0b
helm template . --name-template guestbook-e2e --namespace guestbook-e2e --values ./demo-apps/guestbook/env/e2e/values.yaml --include-crds
```

# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout d0ab341f73bdd6bd64652a2954d839daf6b19b4e
helm template . --name-template guestbook-prd --namespace guestbook-prd --values ./demo-apps/guestbook/env/prd/values.yaml --include-crds
```

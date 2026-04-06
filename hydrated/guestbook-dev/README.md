# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout ab845009a120b15e4620ae8eb379b220034963ea
helm template . --name-template guestbook-dev --namespace guestbook-dev --values ./demo-apps/guestbook/env/dev/values.yaml --include-crds
```

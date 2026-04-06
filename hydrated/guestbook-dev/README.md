# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout c705f9fb0cc06ff3bd407a2eaa16034821868497
helm template . --name-template guestbook-dev --namespace guestbook-dev --values ./demo-apps/guestbook/env/dev/values.yaml --include-crds
```

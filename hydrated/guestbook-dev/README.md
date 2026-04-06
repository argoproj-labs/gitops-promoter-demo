# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 024010b3d57b02800db32f6072ffe3222ed4190d
helm template . --name-template guestbook-dev --namespace guestbook-dev --values ./demo-apps/guestbook/env/dev/values.yaml --include-crds
```

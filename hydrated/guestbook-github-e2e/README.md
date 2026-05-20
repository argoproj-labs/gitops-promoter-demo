# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 7aa7f8d1055492a0be407c701a6c9e8e0c666a70
helm template . --name-template guestbook-github-e2e --namespace guestbook-github-e2e --values ./demo-apps/guestbook/env/e2e/values.yaml --include-crds
```

# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout f26c1b3b59fc639b92728f2b15b2a8b6e7dbcc48
helm template . --name-template guestbook-github-dev --namespace guestbook-github-dev --values ./demo-apps/guestbook/env/dev/values.yaml --include-crds
```

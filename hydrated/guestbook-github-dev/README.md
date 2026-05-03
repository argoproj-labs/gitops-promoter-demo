# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 221d68c85f1eb8aa833254e53be793e8bb1b5f30
helm template . --name-template guestbook-github-dev --namespace guestbook-github-dev --values ./demo-apps/guestbook/env/dev/values.yaml --include-crds
```

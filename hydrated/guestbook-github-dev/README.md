# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 0170db5d17fb8e931b2f1e089fe6dcca9e730a31
helm template . --name-template guestbook-github-dev --namespace guestbook-github-dev --values ./demo-apps/guestbook/env/dev/values.yaml --include-crds
```

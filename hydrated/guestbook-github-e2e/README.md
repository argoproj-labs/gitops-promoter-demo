# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout b0956f3cd317c60c5d3277f3702d0f80fbce29e5
helm template . --name-template guestbook-github-e2e --namespace guestbook-github-e2e --values ./demo-apps/guestbook/env/e2e/values.yaml --include-crds
```

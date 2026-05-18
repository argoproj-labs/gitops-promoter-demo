# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 25f7200235885058998dc4441dcec02233279e89
helm template . --name-template guestbook-github-e2e --namespace guestbook-github-e2e --values ./demo-apps/guestbook/env/e2e/values.yaml --include-crds
```

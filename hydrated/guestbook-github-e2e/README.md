# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 8af2ad06e5e92cfd6e09365bcfe22e8279e94940
helm template . --name-template guestbook-github-e2e --namespace guestbook-github-e2e --values ./demo-apps/guestbook/env/e2e/values.yaml --include-crds
```

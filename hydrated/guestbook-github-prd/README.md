# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 08ff64c2c6f21860e419834ad1c7cc9f4620f61a
helm template . --name-template guestbook-github-prd --namespace guestbook-github-prd --values ./demo-apps/guestbook/env/prd/values.yaml --include-crds
```

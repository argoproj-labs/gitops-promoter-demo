# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout 5a2fa1121bc6f05322fddfd450af6aca0728e667
helm template . --name-template guestbook-github-dev --namespace guestbook-github-dev --values ./demo-apps/guestbook/env/dev/values.yaml --include-crds
```

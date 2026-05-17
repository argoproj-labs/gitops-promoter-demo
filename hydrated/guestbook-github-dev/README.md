# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/argoproj-labs/gitops-promoter-demo
# cd into the cloned directory
git checkout a92d61c70cc957076ad6ddec8cdd1e8a082742db
helm template . --name-template guestbook-github-dev --namespace guestbook-github-dev --values ./demo-apps/guestbook/env/dev/values.yaml --include-crds
```

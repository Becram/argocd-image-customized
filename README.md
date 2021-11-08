prequisite
- install helm
```bash
brew install helm
```
- install helm secret plugin
```bash
helm plugin install https://github.com/jkroepke/helm-secrets --version v3.8.2
```

---
How to apply/update argocd
```bash
cd main-k8s/devops-helm-charts/argocd
helm dependency update
helm upgrade --install argocd . -f values.yaml -f secrets://secrets.yaml -n argocd
```
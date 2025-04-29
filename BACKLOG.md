## 📌 Próximos Passos (Sugestões)

### 🔹 Criar a estrutura para utilizando Helm Charts
- Criar os arquivos de configuração dos resources:
  - `charts/base-resources/`

### 🔹 Adicionar Prometheus AlertManager para alertas
- Ativar no `values.yaml` a configuração do **AlertManager**.
- Configurar **regras personalizadas** para detecção de falhas.

### 🔹 Configurar Grafana Dashboards via Helm
- Criar **ConfigMaps** para provisionamento automático de dashboards customizados.

### 🔹 Criar pipeline para Habilitar Cluster In ArgoCD-Management

```
argocd cluster add arn:aws:eks:us-east-1:590184067017:cluster/tah-demo-cluster --label environment=develop \     
  --label name=tah-demo-cluster \
  --label enable_kube_prometheus_stack=true
```

# Commands

export AWS_ACCESS_KEY_ID="AKIA"          
export AWS_SECRET_ACCESS_KEY="1HP"

kubectl config use-context kind-argocd-main
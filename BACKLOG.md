## 📌 Próximos Passos (Sugestões)

### 🔹 Criar a estrutura para mais ambientes (sandbox, stage, prod)
- Criar os arquivos de configuração:
  - `overlays/sandbox/kustomization.yaml`
  - `overlays/stage/kustomization.yaml`
  - `overlays/prod/kustomization.yaml`
- Cada um deve apontar para seus respectivos namespaces:
  - `monitoring-sandbox`
  - `monitoring-stage`
  - `monitoring-prod`

### 🔹 Adicionar Prometheus AlertManager para alertas
- Ativar no `values.yaml` a configuração do **AlertManager**.
- Configurar **regras personalizadas** para detecção de falhas.

### 🔹 Configurar Grafana Dashboards via Helm
- Criar **ConfigMaps** para provisionamento automático de dashboards customizados.

### 🔹 Habilitar TLS no Ingress
- Utilizar **cert-manager** para provisionamento automático de certificados **TLS**.

### 🔹 Configurar ArgoCD ApplicationSet para todos os ambientes
- Atualizar **ApplicationSet** para incluir:
  - `sandbox`
  - `stage`
  - `prod`
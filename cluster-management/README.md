# GitOps para Gerenciamento de Add-ons no Kubernetes (AWS)

Este repositório implementa uma estrutura GitOps para o gerenciamento de add-ons em clusters Kubernetes provisionados na AWS. Ele segue uma abordagem organizada e modular, utilizando ArgoCD como motor de sincronização e controle de estado desejado.

## Estrutura do Repositório

```
cluster-management
├── bootstraps
│   ├── cluster-init
│   ├── control-plane
│   └── gitops-root.yaml
├── charts
├── clusters
├── environments
└── scripts
```

### 1. `bootstraps/`

Contém os manifestos iniciais para bootstrapping do cluster com ArgoCD e os projetos necessários.

* **`cluster-init/`**: Recursos iniciais aplicados diretamente via `kubectl` para configurar o ArgoCD no cluster e registrar os projetos principais:

  * `bootstrap-app-argocd-projects.yaml`: Criação dos projetos ArgoCD.
  * `bootstrap-app-controle-plane-aws.yaml`: AppSet para add-ons específicos da AWS.
  * `bootstrap-app-controle-plane-oss.yaml`: AppSet para add-ons open-source (OSS).

* **`control-plane/`**: Estrutura dos add-ons organizados por tipo e o projeto ArgoCD:

  * `addons/aws/`: Add-ons específicos para serviços gerenciados AWS (ex: EBS, EFS, Fluent Bit, ALB Controller).
  * `addons/oss/`: Add-ons open-source amplamente utilizados (ex: Karpenter, Prometheus, NGINX, Crossplane).
  * `argocd-config/apps-projects.yaml`: Criação de projetos do ArgoCD para organizar os add-ons em ambientes.

* **`gitops-root.yaml`**: Manifesto raiz que referencia os demais AppSets e define o ponto de entrada para o GitOps no ArgoCD.

### 2. `charts/resources/`

Contém um Helm Chart genérico utilizado como base para provisionar recursos comuns em múltiplos clusters.

* `Chart.yaml`, `values.yaml`: Definições padrão do chart.
* `templates/resources.yaml`: Template que define os recursos a serem aplicados com base nos valores.

### 3. `clusters/`

Contém sobrecargas específicas para clusters individuais (por nome).

* Ex: `cpe-operation/addons/crossplane/`: Configurações customizadas do add-on Crossplane para o cluster `cpe-operation`.

### 4. `environments/`

Contém configurações específicas de valores por ambiente (ex: default, develop).

* `default/addons/`: Configurações default aplicadas a todos os clusters (se não sobrescritas).
* `develop/addons/`: Configurações para o ambiente de desenvolvimento.

  * Exemplo: `ingress-nginx/resources/forwading-ingress-alb.yaml`: Redirecionamento de tráfego ALB para o NGINX.

### 5. `scripts/`

Automatizações para facilitar operações com o repositório GitOps.

* `create_new_cluster.sh`: Script para adicionar um novo cluster ao repositório GitOps.
* `validate_manifests.sh`: Validação dos manifests YAML para consistência e segurança.

---

## Fluxo de Bootstrapping

1. **Aplicar os manifestos em `bootstraps/cluster-init/` com `kubectl`** para criar o ArgoCD e os projetos.
2. **ArgoCD sincroniza `gitops-root.yaml`**, que referencia todos os AppSets dos add-ons por tipo.
3. **Cada AppSet sincroniza os manifests definidos em `environments/`, `clusters/` e `charts/`.**

---

## Convenções Utilizadas

* AppSets separados por tipo: `aws` (gerenciado) e `oss` (open-source).
* Valores por ambiente e cluster segregados para máxima flexibilidade.
* Anotações e labels padronizadas para rastreamento e automação.

---

## Próximos Passos

* Documentar cada AppSet com detalhes de versionamento e comportamento.
* Adicionar validação contínua via CI/CD (ex: GitHub Actions ou Jenkins).
* Implementar testes de validação de ambientes com `kubeval` ou `kubeconform`.

---

Para dúvidas ou contribuições, entre em contato com a equipe de Plataforma.
# gitops-poc

## 1. Cluster Management
Este repositório contém todos os recursos necessários para gerenciar o cluster Kubernetes e os serviços de suporte. Exemplo de estrutura:

```
cluster-management/
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus-deployment.yaml
│   │   ├── prometheus-service.yaml
│   │   ├── prometheus-configmap.yaml
│   ├── grafana/
│   │   ├── grafana-deployment.yaml
│   │   ├── grafana-service.yaml
│   │   ├── grafana-dashboards-configmap.yaml
├── alb-controller/
│   ├── alb-deployment.yaml
│   ├── alb-rbac.yaml
├── gitlab-runner/
│   ├── gitlab-runner-deployment.yaml
│   ├── gitlab-runner-config.yaml
├── namespaces/
│   ├── monitoring-namespace.yaml
│   ├── gitlab-runner-namespace.yaml
├── README.md
```

## 2. Application Management
Este repositório contém as aplicações do produto. Exemplo de estrutura:

```
application-management/
├── app1/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
├── app2/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
├── README.md
```

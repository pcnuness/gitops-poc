## 📌 Próximos Passos (Sugestões)

### 🔹 Configurar App para monitoramento dos control-plane
- Criar **App** para monitoramento das AppSets e App

### 🔹 Criar a estrutura para utilizando Helm Charts
- Criar os arquivos de configuração dos resources:
  - `charts/base-resources/`

### 🔹 Adicionar Prometheus AlertManager para alertas
- Ativar no `values.yaml` a configuração do **AlertManager**.
- Configurar **regras personalizadas** para detecção de falhas.

### 🔹 Criar pipeline para Habilitar Cluster In ArgoCD-Management

#### Observability Stack
```
argocd cluster add arn:aws:eks:us-east-1:730335564649:cluster/tah-demo-cluster \
  --name tah-demo-project \
  --label environment=develop \
  --label enable_kube_prometheus_stack=true \
  --annotation addons_repo_revision=develop \
  --annotation addons_repo_basepath=cluster-management/ \
  --annotation addons_repo_url=https://github.com/pcnuness/gitops-poc.git
```

#### Ingress Nginx and AWS LoadBalaner Controller
```
argocd cluster add arn:aws:eks:us-east-1:590183702475:cluster/eks-infa-ops-services \
  --name application-dev-services \
  --label environment=develop \
  --label enable_ingress_nginx=true \
  --annotation aws_vpc_id=vpc-089db93fec5de56cb \
  --annotation aws_cluster_name=application-dev-services \
  --annotation aws_load_balancer_controller_iam_role_arn=arn:aws:iam::590183702475:role/cpe-application-dev-services-aws-load-balancer-controller-irsa \
  --annotation aws_load_balancer_controller_service_account=aws-load-balancer-controller \
  --annotation aws_load_balancer_controller_namespace=kube-system \
  --annotation addons_repo_revision=develop \
  --annotation addons_repo_basepath=cluster-management/ \
  --annotation addons_repo_url=https://github.com/pcnuness/gitops-poc.git
```

argocd cluster add arn:aws:eks:us-east-1:381492233961:cluster/gitops-management-services \
  --name gitops-management-services \
  --label enable_aws_ebs_csi_resources=false \
  --label enable_aws_load_balancer_controller=false \
  --label enable_ingress_nginx=false \
  --label enable_kube_prometheus_stack=false \
  --label enable_metrics_server=false \
  --label environment=develop \
  --annotation addons_repo_basepath=cluster-management/ \
  --annotation addons_repo_revision=develop \
  --annotation addons_repo_url=https://github.com/pcnuness/gitops-poc \
  --annotation aws_cluster_name=gitops-management-services \
  --annotation aws_load_balancer_controller_iam_role_arn=arn:aws:iam::381492233961:role/gitops-management-services-aws-load-balancer-controller-irsa \
  --annotation aws_load_balancer_controller_namespace=kube-system \
  --annotation aws_load_balancer_controller_service_account=aws-load-balancer-controller \
  --annotation aws_vpc_id=vpc-


# Commands

export AWS_ACCESS_KEY_ID="AKI"          
export AWS_SECRET_ACCESS_KEY="HiC"

kubectl config use-context kind-argocd-main
# gitops-poc

## 1. Cluster Management
Este repositório contém todos os recursos necessários para gerenciar o cluster Kubernetes e os serviços de suporte. Exemplo de estrutura:

```
├── README.md
├── cluster-management
│   ├── applicationset
│   │   ├── applicationset.yaml
│   │   ├── kustomization.yaml
│   │   └── project.yaml
│   └── monitoring
│       ├── base
│       │   ├── grafana
│       │   │   ├── kustomization.yaml
│       │   │   └── values.yaml
│       │   └── kustomization.yaml
│       └── overlays
│           ├── develop
│           │   ├── kustomization.yaml
│           │   └── values.yaml
│           └── sandbox
│               ├── kustomization.yaml
│               └── values.yaml
```

```
kind create cluster --name cpe-operation --config kind-config.yaml
k create namespace argocd
k -n argocd apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
k create namespace ingress-nginx
k -n ingress-nginx apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

## Configurando Acesso ao Argo CD via Ingress no Kind

Este guia detalha os passos necessários para configurar o acesso ao Argo CD via ingress-nginx em um cluster Kind, permitindo acesso nas portas 80 e 443.

---

### **1. Criar o Cluster Kind com Port Forwarding**
Criamos um cluster Kind configurado para mapear as portas 80 e 443 do host para o contêiner, garantindo que possamos acessar o Argo CD externamente.

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: kindest/node:v1.31.0
    extraPortMappings:
      - containerPort: 443
        hostPort: 443
      - containerPort: 80
        hostPort: 80
    labels:
      ingress-ready: "true"
  - role: worker
    image: kindest/node:v1.31.0
    labels:
      tier: frontend
  - role: worker
    image: kindest/node:v1.31.0
    labels:
      tier: backend
```

### **2. Criar os Namespaces e Instalar o Argo CD e ingress-nginx**

#### Criar namespace do Argo CD e instalar os manifests:
```bash
kubectl create namespace argocd
kubectl -n argocd apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### Criar namespace do ingress-nginx e instalar os manifests:
```bash
kubectl create namespace ingress-nginx
kubectl -n ingress-nginx apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

### **3. Ajustar a Configuração do ingress-nginx**

Habilitamos o SSL Passthrough no ingress-nginx para que o tráfego criptografado HTTPS possa ser passado diretamente para o Argo CD.

- **Editar o deployment do ingress-nginx e adicionar o argumento `--enable-ssl-passthrough`:**
```bash
kubectl edit deployment ingress-nginx-controller -n ingress-nginx
```
Adicione `--enable-ssl-passthrough` na lista de argumentos do contêiner.

### **4. Criar o Ingress para o Argo CD**

Aplicamos o recurso Ingress corrigido para rotear o tráfego HTTPS diretamente para o `argocd-server`.

```bash
kubectl apply -f - <<EOF                                          
apiVersion: networking.k8s.io/v1                                                                 
kind: Ingress                   
metadata:                                                                                                                           
  name: argocd-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              name: https
  tls:
  - hosts:
    - argocd.local
EOF
```

#### **Correções feitas nessa versão:**
- Adicionamos a anotação `nginx.ingress.kubernetes.io/ssl-passthrough: "true"` para que o Ingress encaminhe o tráfego HTTPS sem terminar a conexão SSL.
- Garantimos que o backend use a porta **`https`** (o serviço `argocd-server` já expõe essa porta).
- Adicionamos a configuração **`tls:`** para permitir o uso correto do SSL.

### **5. Configurar o DNS Local**

Como estamos utilizando o domínio `argocd.local`, precisamos adicioná-lo ao nosso `/etc/hosts` para resolução de DNS local.

```bash
echo "127.0.0.1 argocd.local" | sudo tee -a /etc/hosts
```

### **6. Testar o Acesso ao Argo CD**
Agora podemos testar o acesso ao Argo CD via navegador ou usando `curl`:

```bash
curl -k https://argocd.local
```

Ou acessar no navegador:
➡️ **https://argocd.local**

---

#### **Conclusão**

Seguindo esse passo a passo, conseguimos configurar corretamente o Argo CD no Kind, permitindo o acesso via ingress-nginx nas portas 80 e 443. 🚀
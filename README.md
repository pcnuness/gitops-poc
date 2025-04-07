# gitops-poc

## 1. Cluster Management

Análise Detalhada
1. bootstrap/workloads
Esta abordagem é excelente para manter a consistência entre clusters e facilitar a implantação em escala.

Sugestões:

Considere criar subdirerórios para categorizar workloads (ex: monitoring, security, networking, finops).
Inclua um README.md explicando o propósito e como adicionar novos workloads.

2. bootstrap/control-plane
A separação do plano de controle é uma prática recomendada, especialmente para ambientes de produção de grande escala.

Sugestões:

Considere criar subdirerórios para categorizar serviços especificos para rodar no cluster cerntral (ex: argocd-config).
Adicione documentação clara sobre os pré-requisitos para o cluster de controle.
Inclua scripts de validação para garantir que o cluster atenda aos requisitos antes da implantação.

1. charts
Centralizar charts personalizados é uma ótima prática para reutilização e manutenção.

Sugestões:

Implemente versionamento semântico para seus charts.
Considere adicionar testes automatizados para validar os charts.

4. environments
Esta estrutura permite uma clara separação de configurações por ambiente, facilitando a gestão do ciclo de vida da aplicação.

Sugestões:

Implemente um sistema de herança de configurações (ex: base -> dev -> staging -> prod).
Utilize ferramentas como Kustomize para gerenciar diferenças entre ambientes.

5. clusters
Excelente para gerenciar configurações específicas de cluster, permitindo customizações finas.

Sugestões:

Implemente um sistema de rotulagem para clusters (ex: região, tipo de workload, etc.).

Este repositório contém todos os recursos necessários para gerenciar o cluster Kubernetes e os serviços de suporte. Exemplo de estrutura:


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


# Adicionar --enable-helm na Configuração do ArgoCD
kubectl patch cm -n argocd argocd-cm --type merge -p '{"data": {"kustomize.buildOptions": "--enable-helm"}}'

# Verifique se a alteração foi aplicada corretamente
kubectl get cm -n argocd argocd-cm -o yaml | grep kustomize.buildOptions

# Recuperar senha do Admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
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


## Configuração do ArgoCD com ngrok (Modo Insecure)

Este guia detalha os ajustes necessários para expor o ArgoCD remotamente via **ngrok**, evitando loops de redirecionamento HTTPS e garantindo um acesso funcional.

### **1. Ajustar a Configuração do ArgoCD para HTTP**
Por padrão, o ArgoCD pode estar configurado para redirecionar **HTTP para HTTPS**, o que causa o erro **ERR_TOO_MANY_REDIRECTS**.

Para permitir conexões HTTP diretas:

#### **Editar o ConfigMap do ArgoCD**
Execute o seguinte comando:

```bash
kubectl edit cm argocd-cmd-params-cm -n argocd
```

No editor que abrir, encontre e adicione ou edite esta linha dentro da chave `data`:

```yaml
data:
  server.insecure: "true"
```

#### **Reiniciar o ArgoCD Server**
Após editar o ConfigMap, reinicie o deployment do ArgoCD para aplicar a configuração:

```bash
kubectl rollout restart deployment argocd-server -n argocd
```

---

### **2. Configurar o Port Forwarding do ArgoCD**
Agora, precisamos expor a porta correta do ArgoCD. Para isso, redirecione a porta **80** do serviço ArgoCD para a **8080** localmente:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Isso permitirá que o tráfego HTTP seja acessado diretamente na porta **8080** da máquina local.

---

### **3. Expor o ArgoCD via ngrok**
Agora que o serviço está exposto corretamente, podemos utilizar o `ngrok` para disponibilizar o ArgoCD remotamente.

Execute o seguinte comando para criar um túnel HTTP **sem forçar TLS**:

```bash
ngrok http 8080
```

O **ngrok** gerará um endereço público, semelhante a:

```
Forwarding                    https://SEU_NGROK_URL -> http://localhost:8080
```

Agora, você pode acessar o ArgoCD via **https://SEU_NGROK_URL**.

---

### **4. Testar o Acesso ao ArgoCD**

#### **Acesso pelo Navegador**
Abra o navegador e acesse o endereço gerado pelo ngrok:

```
https://SEU_NGROK_URL
```

Se tudo estiver correto, a interface do ArgoCD será carregada.

#### **Acesso via CLI**
Para acessar o ArgoCD via CLI, utilize o seguinte comando:

```bash
argocd login SEU_NGROK_URL --username admin --password SENHA --insecure --grpc-web
```

Caso precise recuperar a senha do admin, execute:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
```

---

### **Conclusão**
Com esses ajustes, agora o **ArgoCD** pode ser acessado remotamente via **ngrok**, sem loops de redirecionamento HTTPS e sem erros de conexão. 🚀


## Nova Stack

### adicionar annotate no cluster
```
kubectl annotate secret -n argocd cluster-kubernetes.default.svc-3396314289 addons_repo_url=https://github.com/pcnuness/gitops-poc addons_repo_revision=develop --overwrite
```

### Adicionando Label no cluster

```
kubectl label secret cluster-kubernetes.default.svc-3396314289 -n argocd enable_kube_prometheus_stack=true --overwrite
```


## The Magic

### Stack Observability
```
k get pods -n kube-system
```
### Forwarding Observabiliy
```
 kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-grafana 3000:80
 prom-operator
```
#!/bin/bash

# Number of clusters to create
N=${1:-3}  # Default to 3 if not specified

# Base port for API server
BASE_API_PORT=6443

# Base port for Ingress HTTP
BASE_HTTP_PORT=80

# Base port for Ingress HTTPS
BASE_HTTPS_PORT=443

for i in $(seq 1 $N)
do
  CLUSTER_NAME="kind-cluster-$i"
  API_PORT=$((BASE_API_PORT + i - 1))
  HTTP_PORT=$((BASE_HTTP_PORT + i - 1))
  HTTPS_PORT=$((BASE_HTTPS_PORT + i - 1))
  
  # Create kind-config-${i}.yaml
  cat << EOF > kind-config-${i}.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: ${API_PORT}
nodes:
- role: control-plane
  image: kindest/node:v1.31.0
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: ${HTTP_PORT}
    protocol: TCP
  - containerPort: 443
    hostPort: ${HTTPS_PORT}
    protocol: TCP
- role: worker
  image: kindest/node:v1.31.0
  labels:
    tier: frontend
- role: worker
  image: kindest/node:v1.31.0
  labels:
    tier: backend
EOF

  # Create the cluster
  kind create cluster --config kind-config-${i}.yaml

  # Wait for the cluster to be ready
  kubectl wait --for=condition=Ready nodes --all --timeout=300s --context kind-${CLUSTER_NAME}

  # Install Nginx Ingress
  kubectl create namespace ingress-nginx --context kind-${CLUSTER_NAME}
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml --context kind-${CLUSTER_NAME}

  # Wait for Ingress to be ready
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s \
    --context kind-${CLUSTER_NAME}

  # Install ArgoCD
  kubectl create namespace argocd --context kind-${CLUSTER_NAME}
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --context kind-${CLUSTER_NAME}

  # Wait for ArgoCD to be ready
  kubectl wait --namespace argocd \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/name=argocd-server \
    --timeout=300s \
    --context kind-${CLUSTER_NAME}

  # Configure ArgoCD Ingress
  cat << EOF | kubectl apply -f - --context kind-${CLUSTER_NAME}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: nginx
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
              number: 443
EOF

  echo "Cluster ${CLUSTER_NAME} created and configured with API server on port ${API_PORT}, HTTP on ${HTTP_PORT}, and HTTPS on ${HTTPS_PORT}"
  echo "ArgoCD is accessible at https://argocd-${CLUSTER_NAME}.localhost:${HTTPS_PORT}"
done
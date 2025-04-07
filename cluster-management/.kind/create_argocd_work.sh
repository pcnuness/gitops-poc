#!/bin/bash

# Number of worker clusters to create
N=${1:-3}  # Default to 3 if not specified

# Base port for API server
BASE_API_PORT=6443

# Base port for Ingress HTTP
BASE_HTTP_PORT=80

# Base port for Ingress HTTPS
BASE_HTTPS_PORT=443

# Function to create a cluster
create_cluster() {
    local cluster_name=$1
    local api_port=$2
    local http_port=$3
    local https_port=$4
    local is_main=${5:-false}

    # Create kind-config-${cluster_name}.yaml
    cat << EOF > kind-config-${cluster_name}.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${cluster_name}
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: ${api_port}
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
    hostPort: ${http_port}
    protocol: TCP
  - containerPort: 443
    hostPort: ${https_port}
    protocol: TCP
- role: worker
  image: kindest/node:v1.31.0
EOF

    # Create the cluster
    kind create cluster --config kind-config-${cluster_name}.yaml

    # Wait for the cluster to be ready
    kubectl wait --for=condition=Ready nodes --all --timeout=300s --context kind-${cluster_name}

    # Install Nginx Ingress
    kubectl create namespace ingress-nginx --context kind-${cluster_name}
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml --context kind-${cluster_name}

    # Wait for Ingress to be ready
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=90s \
      --context kind-${cluster_name}

    if [ "$is_main" = true ] ; then
        # Install ArgoCD on main cluster
        kubectl create namespace argocd --context kind-${cluster_name}
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --context kind-${cluster_name}

        # Wait for ArgoCD to be ready
        kubectl wait --namespace argocd \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/name=argocd-server \
          --timeout=300s \
          --context kind-${cluster_name}

        # Configure ArgoCD Ingress
        cat << EOF | kubectl apply -f - --context kind-${cluster_name}
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
  - host: argocd.localhost
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
    fi

    echo "Cluster ${cluster_name} created and configured with API server on port ${api_port}, HTTP on ${http_port}, and HTTPS on ${https_port}"
}

# Create main cluster with ArgoCD
create_cluster "argocd-main" $BASE_API_PORT $BASE_HTTP_PORT $BASE_HTTPS_PORT true

# Create worker clusters
for i in $(seq 1 $N)
do
    API_PORT=$((BASE_API_PORT + i))
    HTTP_PORT=$((BASE_HTTP_PORT + i))
    HTTPS_PORT=$((BASE_HTTPS_PORT + i))
    create_cluster "worker-project-$i" $API_PORT $HTTP_PORT $HTTPS_PORT
done

# Configure ArgoCD to manage worker clusters
for i in $(seq 1 $N)
do
    CLUSTER_NAME="worker-project-$i"
    
    # Get the kubeconfig for the worker cluster
    KIND_KUBECONFIG=$(kind get kubeconfig --name ${CLUSTER_NAME})
    
    # Add the cluster to ArgoCD
    kubectl exec -it -n argocd deploy/argocd-server -- argocd cluster add kind-${CLUSTER_NAME} --kubeconfig "${KIND_KUBECONFIG}" --yes
done

echo "ArgoCD is accessible at https://argocd.localhost:${BASE_HTTPS_PORT}"
echo "ArgoCD initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --context kind-argocd-main | base64 -d
echo
echo "Use 'admin' as the username to log in to ArgoCD"
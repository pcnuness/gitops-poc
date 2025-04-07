#!/bin/bash

# Script para criar um novo cluster
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <nome-do-cluster> <ambiente>"
    exit 1
fi

CLUSTER_NAME=$1
ENVIRONMENT=$2

# Cria a estrutura de pastas para o novo cluster
mkdir -p clusters/$CLUSTER_NAME/addons/{kube-prometheus-stack,metrics-server,crossplane}

# Copia os valores padrão do ambiente para o novo cluster
cp environments/$ENVIRONMENT/addons/kube-prometheus-stack/values.yaml clusters/$CLUSTER_NAME/addons/kube-prometheus-stack/
cp environments/$ENVIRONMENT/addons/metrics-server/values.yaml clusters/$CLUSTER_NAME/addons/metrics-server/
cp environments/$ENVIRONMENT/addons/crossplane/values.yaml clusters/$CLUSTER_NAME/addons/crossplane/

echo "Estrutura para o cluster $CLUSTER_NAME criada no ambiente $ENVIRONMENT."

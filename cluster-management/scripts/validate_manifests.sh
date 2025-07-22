#!/bin/bash

# Valida os manifestos Kubernetes
for file in $(find . -name "*.yaml" -o -name "*.yml"); do
    echo "Validando $file"
    kubectl apply --dry-run=client -f $file
    if [ $? -ne 0 ]; then
        echo "Erro ao validar $file"
        exit 1
    fi
done

echo "Todos os manifestos são válidos."

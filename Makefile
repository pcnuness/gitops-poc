# Nome do script
SCRIPT := ./create_argocd_work_v1.sh

# Quantidade padrão de clusters worker
CLUSTERS ?= 1

# IP padrão do ArgoCD (para /etc/hosts)
ARGOCD_HOST := argocd.local

# Target: cria argocd-main + N clusters worker
create:
	@echo "🚀 Criando clusters (argocd-main + $(CLUSTERS) workers)..."
	$(SCRIPT) $(CLUSTERS)

# Target: limpa todos os clusters Kind e a rede Docker
destroy:
	@echo "🧹 Limpando ambiente local..."
	$(SCRIPT) cleanup

# Target: faz login no ArgoCD via CLI
login:
	@echo "🔐 Realizando login no ArgoCD..."
	@ARGOCD_PASS=$$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" --context kind-argocd-main | base64 -d); \
	argocd login $(ARGOCD_HOST) --insecure --username admin --password $$ARGOCD_PASS

# Target: mostra os clusters registrados no ArgoCD
status:
	@echo "🔍 Clusters registrados no ArgoCD:"
	argocd cluster list

# Target: abre a interface do ArgoCD no navegador
open:
	@echo "🌐 Abrindo https://$(ARGOCD_HOST)"
	@open https://$(ARGOCD_HOST) || xdg-open https://$(ARGOCD_HOST) || echo "Abra manualmente: https://$(ARGOCD_HOST)"

# Ajuda
help:
	@echo "Targets disponíveis:"
	@echo "  make create      -> Cria argocd-main + N clusters Kind (use CLUSTERS=3)"
	@echo "  make destroy     -> Remove todos os clusters e rede kind-network"
	@echo "  make login       -> Faz login no ArgoCD via CLI"
	@echo "  make status      -> Lista os clusters registrados no ArgoCD"
	@echo "  make open        -> Abre o ArgoCD no navegador"
	@echo "  make help        -> Mostra esta ajuda"

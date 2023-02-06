.PHONY: default help

default: help
help: ## display make targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(word 1, $(MAKEFILE_LIST)) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m make %-20s -> %s\n\033[0m", $$1, $$2}'



.PHONY: up-kind
up-kind: ## setup local kind cluster.
	@bash -c "kind create cluster --config infra/local/kind-config-with-mounts.yaml"
	@bash -c "echo 'installing cert-manager'"
	@bash -c "echo '.... cert-manager may take a few minutes'"
	@bash -c "kubectl apply -f infra/local/cert-manager.yaml 2>&1 >/dev/null"
	@bash -c "kubectl wait deployment -n cert-manager cert-manager-webhook --for condition=Available=True --timeout=120s"
	@bash -c "echo 'installing metrics server'"
	@bash -c "kubectl apply -f infra/local/metrics_server.yaml 2>&1 >/dev/null"
	@bash -c "kubectl wait deployment -n kube-system metrics-server --for condition=Available=True --timeout=120s"


.PHONY: ingress
ingress: ## setup cluster for ingress
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "echo 'installing ingress'"
	@bash -c "echo '.... ingress may take a few minutes'"
	@bash -c "kubectl apply -f infra/local/nginx-ingress.yaml 2>&1 >/dev/null"
	@bash -c "kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s"


.PHONY: helm-prep
helm-prep: ## helm-prep
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
	@bash -c "helm repo add stable https://charts.helm.sh/stable"
	@bash -c "helm repo add stable https://charts.helm.sh/stable"
	@bash -c "helm repo update"


.PHONY: install-prometheus
install-prometheus: ## install-prometheus
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl create ns monitoring"
	@bash -c "helm install kind-prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --set prometheus.service.nodePort=30000 --set prometheus.service.type=NodePort --set grafana.service.nodePort=31000 --set grafana.service.type=NodePort --set alertmanager.service.nodePort=32000 --set alertmanager.service.type=NodePort --set prometheus-node-exporter.service.nodePort=32001 --set prometheus-node-exporter.service.type=NodePort"
	@bash -c "echo 'Port-forward'"
	@bash -c "echo 'k -n monitoring port-forward service/alertmanager-operated 9093:9093'"
	@bash -c "echo 'k -n monitoring port-forward service/kind-prometheus-grafana 3000:80'"


.PHONY: install-argo
install-argo: ## install argo
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl create ns argo"
	@bash -c "kubectl apply -n argo -f infra/local/argo-workflow-v3.4.1.secure.yaml"
	@bash -c "kubectl wait deployment -n argo argo-server --for condition=Available=True --timeout=120s"
	@bash -c "kubectl wait deployment -n argo workflow-controller --for condition=Available=True --timeout=120s"


.PHONY: install-argo-events
install-argo-events: ## install argo-events
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl create ns argo-events"
	@bash -c "kubectl apply  -f infra/local/argo-events0.yaml"
	@bash -c "kubectl apply  -f infra/local/argo-events-install-validating-webhook.yaml"


.PHONY: install-tekton
install-tekton: ## install tekton
	@bash -c "echo 'installing tekton: pipelines, triggers, interceptors and read/write dashboard'"
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl apply  -f infra/local/tekton/pipelines.yaml"
	@bash -c "kubectl wait deployment -n tekton-pipelines tekton-pipelines-controller --for condition=Available=True --timeout=420s"
	@bash -c "kubectl wait deployment -n tekton-pipelines tekton-pipelines-webhook --for condition=Available=True --timeout=420s"
	@bash -c "echo 'installing triggers and interceptors'"
	@bash -c "kubectl apply -f infra/local/tekton/triggers.yaml"
	@bash -c "kubectl apply -f infra/local/tekton/interceptors.yaml"
	@bash -c "echo '... waiting for triggers and interceptors to be ready'"
	@bash -c "kubectl wait deployment -n tekton-pipelines tekton-triggers-controller --for condition=Available=True --timeout=420s"
	@bash -c "kubectl wait deployment -n tekton-pipelines tekton-triggers-webhook --for condition=Available=True --timeout=420s"
	@bash -c "echo '...installing dashboard in read/write mode'"
	@bash -c "kubectl apply -f infra/local/tekton/dashboard.yaml"
	@bash -c "kubectl wait deployment -n tekton-pipelines tekton-dashboard --for condition=Available=True --timeout=420s"


.PHONY: patch-auth-mode
patch-auth-mode: ## patch auth-mode
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "./infra/local/patch.sh"


.PHONY: port-forward
port-forward: ## port-forward
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "echo 'kubectl -n argo port-forward deployment.apps/argo-server 2746:2746'"
	@bash -c "echo -e '\n\n Chrome type in:  thisisunsafe\n\n'"
	@bash -c "kubectl -n argo port-forward deployment.apps/argo-server 2746:2746"
	@bash -c "echo 'This will serve the user interface on https://localhost:2746'"

.PHONY: roles-argo
roles-argo: ## create roles in argo
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl create sa cicd -n argo"
	@bash -c "kubectl create rolebinding cicd --role=argo-role --serviceaccount=argo:cicd"
	@bash -c "kubectl create clusterrolebinding cr-cicd-argo --clusterrole=argo-cluster-role --serviceaccount=argo:cicd"
	@bash -c "kubectl create clusterrolebinding cr-template-cicd-argo --clusterrole=argo-clusterworkflowtemplate-role --serviceaccount=argo:cicd"


.PHONY: roles-dev
roles-dev: ## create roles in argo
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl create ns dev"
	@bash -c "kubectl create sa cicd -n dev"
	@bash -c "kubectl create rolebinding cicd --role=argo-role --serviceaccount=dev:cicd -n dev"
	@bash -c "kubectl create clusterrolebinding cRcicd --clusterrole=argo-cluster-role --serviceaccount=dev:cicd"
	@bash -c "kubectl create clusterrolebinding cRTemplatecicd --clusterrole=argo-clusterworkflowtemplate-role --serviceaccount=dev:cicd"


.PHONY: argo-cd
argo-cd: ## install argo-cd
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl create ns argocd"
	@bash -c "kubectl apply -n argocd -f infra/local/argo-cd.yaml"
	@bash -c "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo"


.PHONY: argo-cd-password
argo-cd-password: ## get argo-cd password
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "echo 'user: admin'"
	@bash -c "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo"


.PHONY: remove-argo
remove-argo: ## install argo
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl delete -n argo -f infra/local/argo-workflow-v3.4.1.secure.yaml"
	@bash -c "kubectl delete ns argo"


.PHONY: remove-argo-events
remove-argo-events: ## remove argo-events
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl delete  -f infra/local/argo-events0.yaml"
	@bash -c "kubectl delete  -f infra/local/argo-events-install-validating-webhook.yaml"
	@bash -c "kubectl delete ns argo-events"


.PHONY: remove-roles-argo
remove-roles-argo: ## create roles in argo
	@bash -c "kubectl config set-cluster kind-kind"
	@bash -c "kubectl delete sa cicd -n argo"
	@bash -c "kubectl delete rolebinding cicd"
	@bash -c "kubectl delete clusterrolebinding cr-cicd-argo"
	@bash -c "kubectl delete clusterrolebinding cr-template-cicd-argo'

.PHONY: down-kind
down-kind: ## tear down local kind cluster
	@bash -c "kind delete cluster"

#!/usr/bin/env bash
_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_dir}/utils.sh"

##########################################################
# Curls the given path at http://localhost.
# Globals:
#   None
# Arguments:
#   _path     - The path to query. Appends to http://localhost/
#   _tries    - The number of times to attempt the request.
#   _interval - The time between tries (in seconds).
##########################################################
# shellcheck disable=SC2120
function validate_ingress() {
  local _path=${1:-""}
  local _tries=${2:-10}
  local _interval=${3:-3}

  _info "Curling ingress at http://localhost/${_path} to validate... (timeout=$((_interval * _tries))s)"
  # shellcheck disable=SC1073
  for ((i=0; i<10; i++)); do
    if curl --output /dev/null --silent --head --fail "http://localhost/${_path}"; then
      sleep "${_interval}"
    else
      _info "Successfully sent curl request to http://localhost/${_path}" && return
    fi
  done
  _error "Failed to validate ingress..."
}

##########################################################
# Annotates the provided ingress to be picked up by Ambassador.
# Globals:
#   None
# Arguments:
#   _ingress_type       - The type of the ingress controller (default: "nginx")
#   _ingress_namespace  - The namespace of the ingress.
#   _ingress_name       - The name of the ingress.
##########################################################
function annotate_for_ambassador() {
  local _ingress_type=${1:-"nginx"}
  local _ingress_namespace=${2}
  local _ingress_name=${3}

  if [[ "${_ingress_type}" == "ambassador" ]]; then
    _info "Annotating ingress object to allow Ambassador to recognize the ingress..."
    kubectl annotate ingress -n "${_ingress_namespace}" "${_ingress_name}" kubernetes.io/ingress.class=ambassador
  fi
}

##########################################################
# Deploys and validates Ambassador as the Ingress.
# Globals:
#   None
# Arguments:
#   None
##########################################################
function ambassador() {
  _info "Setting up Ambassador Ingress..."
  _info "Installing CRDs..."
  kubectl apply -f https://github.com/datawire/ambassador-operator/releases/download/v1.3.0/ambassador-operator-crds.yaml
  sleep 1

  _info "Installing Ambassador operator..."
  kubectl apply -n ambassador -f https://github.com/datawire/ambassador-operator/releases/download/v1.3.0/ambassador-operator-kind.yaml
  kubectl wait --timeout=180s -n ambassador --for=condition=deployed ambassadorinstallations/ambassador

  _info "Validating Ambassador Ingress is working..."
  _info "Installing echoservers and ingress object..."
  kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml

  annotate_for_ambassador "ambassador" "default" "example-ingress"
  validate_ingress "foo" 20 3

  _info "Removing echoservers and ingress object..."
  kubectl delete -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml --force=true --grace-period=0
}

##########################################################
# Deploys and validates Contour as the Ingress.
# Globals:
#   None
# Arguments:
#   None
##########################################################
function contour() {
  _info "Setting up Contour ingress..."
  _info "Installing Contour components..."
  kubectl apply -f https://raw.githubusercontent.com/projectcontour/contour/release-1.18/examples/render/contour.yaml

  _info "Patching Contour daemonset..."
  kubectl patch daemonsets -n projectcontour envoy -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'

  _info "Validating Contour Ingress is working..."
  _info "Installing echoservers and ingress object..."
  kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml

  validate_ingress "foo" 20 3

  _info "Removing echoservers and ingress object..."
  kubectl delete -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml --force=true --grace-period=0
}

##########################################################
# Deploys NGINX as the Ingress.
# Globals:
#   None
# Arguments:
#   None
##########################################################
function nginx() {
  _info "Setting up NGINX Ingress..."
  _info "Installing NGINX Ingress components..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.1/deploy/static/provider/kind/deploy.yaml
  sleep 1

  _info "Waiting for readiness from NGINX controller... (timeout=90s)"
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s

  _info "Validating NGINX Ingress is working..."
  _info "Installing echoservers and ingress object..."
  kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml

  validate_ingress "foo" 20 3

  _info "Removing echoservers and ingress object..."
  kubectl delete -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml --force=true --grace-period=0
}

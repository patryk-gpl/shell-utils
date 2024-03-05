#!/usr/bin/env bash
# This script deploys Jenkins to Minikube
# Docuemntation: https://www.jenkins.io/doc/book/installing/kubernetes/
namespace="${1:-jenkins}"

eLog() {
  GREEN='\033[0;32m'
  RESET='\033[0m'
  echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${RESET}"
}

eWarn() {
  YELLOW='\033[0;33m'
  RESET='\033[0m'
  echo -e "${YELLOW}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${RESET}"
}

eError() {
  RED='\033[0;31m'
  RESET='\033[0m'
  echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${RESET}"
}

checkMinikubeStatus() {
  if minikube status &> /dev/null; then
    return 0
  else
    return 1
  fi
}

createNamespaceIfNotExists() {
  if kubectl get namespace "$namespace" &> /dev/null; then
    eWarn "Namespace $namespace already exists. Skipping.."
  else
    kubectl create namespace "$namespace"
  fi
}

# Main
if checkMinikubeStatus; then
  eLog "Deploy Jenkins to Minikube"
  createNamespaceIfNotExists
else
  eError "Error: Kubernetes is not running on Minikube"
  exit 1
fi

# Functions to work with kustomize

kust_apply() {
  kustomize build | kubectl apply -f -
}

kust_delete() {
  kustomize build | kubectl delete -f -
}

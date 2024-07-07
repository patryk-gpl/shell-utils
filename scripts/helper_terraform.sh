#!/bin/bash
# Terraform helper functions

# Below, not needed for public, required for usgovernment, german, china
export TF_VAR_arm_environment="public"

function tdebugOn() {
  export TF_LOG="DEBUG"
  export TF_LOG_PATH="debug.log"
}

function tdebugOff() {
  unset TF_LOG
}

function tfmt() {
  terraform fmt "$(git rev-parse --show-toplevel)"
}

function tplan() {
  tfmt
  terraform plan -no-color -out=project.tfplan
}

function tapply() {
  tfmt
  terraform apply -no-color project.tfplan
}

function tdestroy() {
  tfmt
  terraform destroy -no-color
}

#############################################################################################
# Initialize Terraform remote backend with Azure Storage and make sure plugins are up-to-date
# Globals:
#  TERRAFORM_STORAGE_ACCESS_KEY - access key to Azure Storage
# Returns:
#  None
#############################################################################################
function tinit() {
  if [[ -z "$TERRAFORM_STORAGE_ACCESS_KEY" ]]; then
    echo "TERRAFORM_STORAGE_ACCESS_KEY environment variable not set. Aborting.."
  fi
  tfmt
  terraform init -backend-config="access_key=$TERRAFORM_STORAGE_ACCESS_KEY" -upgrade
}

function toutput() {
  tfmt
  terraform output -no-color
}

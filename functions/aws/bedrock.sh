if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

aws_bedrock_list_foundation_models() {
  local region="$1"
  local provider="${2:-anthropic}"

  if [[ -z "$region" ]]; then
    echo "Usage: aws_bedrock_list_foundation_models <region> [provider]"
    return 1
  fi

  aws bedrock list-foundation-models --region="$region" --by-provider "$provider" --query "modelSummaries[*].modelId" --output text | tr '\t' '\n' | sort
}

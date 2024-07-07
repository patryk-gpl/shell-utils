#!/usr/bin/env bash
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

ollama_get_tags_via_api() {
  local host=${1:-"localhost"}
  local url="http://$host:11434/api/tags"

  echo "Fetching tags from $url..."
  curl -s "$url" | jq -r '.models[] | [.name, .details.family, .details.parameter_size, .details.quantization_level] | @tsv' | column -t -s $'\t'
}

ollama_pull_all() {
  local max_retries=3
  local failed_models=()

  pull_model() {
    local model=$1
    local retry_count=${2:-0}

    echo "Pulling $model (Attempt $((retry_count + 1)) of $max_retries)..."
    if ollama pull "$model"; then
      echo "Successfully pulled $model"
      return 0
    else
      echo "Failed to pull $model"
      if ((retry_count < max_retries - 1)); then
        pull_model "$model" $((retry_count + 1))
      else
        echo "Max retries reached for $model"
        failed_models+=("$model")
        return 1
      fi
    fi
  }

  local models
  models=$(ollama list | awk 'NR>1 {print $1}')

  while IFS= read -r model; do
    pull_model "$model"
    echo "------------------------"
  done <<<"$models"

  if ((${#failed_models[@]} == 0)); then
    echo "All models have been updated successfully."
  else
    echo "The following models failed to update after $max_retries attempts:"
    printf '%s\n' "${failed_models[@]}"
  fi
}

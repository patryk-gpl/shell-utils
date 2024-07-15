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

ollama_update_all_models() {
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

ollama_update() {
  echo "Updating Ollama..."

  current_version=$(ollama -v | awk '{print $NF}')
  echo "Current Ollama version: $current_version"

  if pgrep -x "ollama" >/dev/null; then
    echo "Ollama is currently running. Stopping Ollama..."
    sudo systemctl stop ollama || sudo killall ollama
    sleep 2 # Give it a moment to fully stop
  fi

  # Backup the current version
  sudo cp /usr/local/bin/ollama "/usr/local/bin/ollama_$current_version"

  if sudo curl -sL https://ollama.com/download/ollama-linux-amd64 -o /usr/local/bin/ollama; then
    if sudo chmod +x /usr/local/bin/ollama; then
      new_version=$(ollama -v | awk '{print $NF}')
      echo "Ollama has been successfully updated to version $new_version."
      if [ "$current_version" = "$new_version" ]; then
        echo "Note: The version number hasn't changed. You might already have the latest version."
      fi
      echo "Starting ollama.."
      sudo systemctl start ollama
    else
      echo "Failed to set executable permissions on Ollama."
      sudo mv "/usr/local/bin/ollama_$current_version" /usr/local/bin/ollama
      return 1
    fi
  else
    echo "Failed to download the latest version of Ollama."
    sudo mv "/usr/local/bin/ollama_$current_version" /usr/local/bin/ollama
    return 1
  fi

  echo "A backup of the previous version ($current_version) has been saved as /usr/local/bin/ollama_$current_version"
}

ollama_uninstall() {
  echo "Uninstalling Ollama..."

  if systemctl is-active --quiet ollama; then
    echo "Stopping Ollama service..."
    sudo systemctl stop ollama
  fi
  if systemctl is-enabled --quiet ollama; then
    echo "Disabling Ollama service..."
    sudo systemctl disable ollama
  fi

  if [ -f /etc/systemd/system/ollama.service ]; then
    echo "Removing Ollama service file..."
    sudo rm /etc/systemd/system/ollama.service
    sudo systemctl daemon-reload
  fi

  ollama_path=$(which ollama)
  if [ -n "$ollama_path" ]; then
    echo "Removing Ollama binary from $ollama_path..."
    sudo rm "$ollama_path"
  else
    echo "Ollama binary not found in PATH."
  fi

  # Remove downloaded models and Ollama data
  if [ -d /usr/share/ollama ]; then
    read -pr "Do you want to remove downloaded models and Ollama data? (y/n): " answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
      echo "Removing Ollama data directory..."
      sudo rm -r /usr/share/ollama
    else
      echo "Skipping removal of downloaded models and Ollama data."
    fi
  fi

  # Remove Ollama user and group
  if id "ollama" &>/dev/null; then
    echo "Removing Ollama user..."
    sudo userdel ollama
  fi
  if getent group ollama >/dev/null; then
    echo "Removing Ollama group..."
    sudo groupdel ollama
  fi

  echo "Ollama uninstallation complete."
  echo "Note: If you have any personal data or configurations in ~/.ollama, you may want to remove those manually."
  echo "Content of ~/.ollama"
  ls -l ~/.ollama
}

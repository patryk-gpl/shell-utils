if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

ollama_copy_model() {
  if [ $# -ne 4 ]; then
    echo "Error: Incorrect number of parameters."
    echo "Usage: ollama_copy_model <model_name> <model_tag> <remote_host> <dest_dir>"
    return 1
  fi

  local model_name="$1"
  local model_tag="$2"
  local remote_host="$3"
  local dest_dir="$4"

  if [[ -z "$model_name" || -z "$model_tag" || -z "$remote_host" || -z "$dest_dir" ]]; then
    echo "Error: All parameters must be non-empty."
    echo "Usage: ollama_copy_model <model_name> <model_tag> <remote_host> <dest_dir>"
    return 1
  fi

  # Local paths
  local local_base="/usr/share/ollama/.ollama"
  local manifest_path="${local_base}/models/manifests/registry.ollama.ai/library/${model_name}/${model_tag}"
  local blobs_dir="${local_base}/models/blobs"

  echo "== Syncing model: $model_name:$model_tag =="

  # Check if manifest file exists
  if [ ! -f "$manifest_path" ]; then
    echo "Error: Manifest file not found for ${model_name}:${model_tag}"
    return 1
  fi

  # Remote paths
  local remote_model_dir="${dest_dir}/models/manifests/registry.ollama.ai/library/${model_name}"
  local remote_blobs_dir="${dest_dir}/models/blobs"

  # Test SSH connection
  if ! ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$remote_host" exit; then
    echo "Error: Cannot connect to remote host $remote_host"
    return 1
  fi

  # Create remote directories
  # shellcheck disable=SC2029
  ssh "$remote_host" "mkdir -p \"$remote_model_dir\" \"$remote_blobs_dir\""

  # Copy manifest file
  echo "Syncing manifest: $manifest_path"
  if ! rsync -aP --info=progress2 -e "ssh -T" "$manifest_path" "${remote_host}:${remote_model_dir}/${model_tag}"; then
    echo "Error: Failed to copy manifest file"
    return 1
  fi

  # Parse manifest and copy blobs
  local blobs_copied=0
  local total_size=0

  # Copy config blob
  local config_digest config_blob
  config_digest=$(jq -r '.config.digest' "$manifest_path")
  config_blob="${blobs_dir}/sha256-${config_digest#sha256:}"
  if [ -f "$config_blob" ]; then
    echo "Syncing config blob $config_blob"
    if rsync -aP --info=progress2 -e "ssh -T" "$config_blob" "${remote_host}:${remote_blobs_dir}/"; then
      ((blobs_copied++))
      total_size=$((total_size + $({ wc -c <"$config_blob"; } 2>/dev/null)))
    else
      echo "Warning: Failed to copy config blob $config_digest"
    fi
  else
    echo "Warning: Config blob $config_digest not found locally"
  fi

  # Copy layer blobs
  while IFS= read -r digest; do
    local local_blob="${blobs_dir}/sha256-${digest#sha256:}"

    if [ -f "$local_blob" ]; then
      echo "Syncing blob $local_blob"
      if rsync -aP --info=progress2 -e "ssh -T" "$local_blob" "${remote_host}:${remote_blobs_dir}/"; then
        ((blobs_copied++))
        total_size=$((total_size + $({ wc -c <"$local_blob"; } 2>/dev/null)))
      else
        echo "Warning: Failed to copy blob $digest"
      fi
    else
      echo "Warning: Blob $digest not found locally"
    fi
  done < <(jq -r '.layers[].digest' "$manifest_path")

  # Output stats
  echo "Model copied: ${model_name}:${model_tag}"
  echo "Files copied: $((blobs_copied + 1)) (${blobs_copied} blobs + 1 manifest)"
  echo "Total size: $(numfmt --to=iec-i --suffix=B --format="%.2f" $total_size)"
}

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
    echo "Ollama is currently running..."
    if [[ "$(uname)" == "Linux" ]]; then
      echo "Stopping Ollama..."
      sudo systemctl stop ollama || sudo killall ollama
      sleep 2 # Give it a moment to fully stop
    elif [[ "$(uname)" == "Darwin" ]]; then
      echo "Running on macOS. Update Ollama via restarting it from the menu bar."
      return 1
    else
      echo "Unknown operating system"
      return 1
    fi
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

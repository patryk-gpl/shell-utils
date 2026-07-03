alias coy="copilot --yolo"
function coy_ollama() {
  local COPILOT_PROVIDER_BASE_URL="http://localhost:11434/v1"
  local COPILOT_MODEL="ornith:9b"

  usage() {
    echo "Usage: coy_ollama [MODEL] [COPILOT_ARGS...]"
    echo "Run Copilot against the local Ollama provider at $COPILOT_PROVIDER_BASE_URL."
    echo ""
    echo "Arguments:"
    echo "  MODEL              Optional model name to use (default: ornith:9b)"
    echo "  COPILOT_ARGS       Additional arguments passed to copilot --yolo"
    echo "  -h, --help         Display this help message"
  }

  case ${1:-} in
    -h | --help)
      usage
      return 0
      ;;
  esac

  if [[ $# -gt 0 ]]; then
    COPILOT_MODEL="$1"
    shift
  fi

  COPILOT_PROVIDER_BASE_URL="$COPILOT_PROVIDER_BASE_URL" COPILOT_MODEL="$COPILOT_MODEL" copilot --yolo "$@"
}

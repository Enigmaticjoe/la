#!/usr/bin/env bash
set -euo pipefail

# Download and verify an abliterated/abliterate model for local Ollama.
# Works with host Ollama or a Docker containerized Ollama instance.

MODEL_TAG="${MODEL_TAG:-mannix/llama3.1-8b-abliterated:latest}"
OLLAMA_CONTAINER="${OLLAMA_CONTAINER:-chimera-ollama}"
OLLAMA_HOST_URL="${OLLAMA_HOST_URL:-http://127.0.0.1:11434}"
RETRIES="${RETRIES:-3}"
TIMEOUT_S="${TIMEOUT_S:-30}"
CREATE_ALIAS="${CREATE_ALIAS:-true}"
ALIAS_TAG="${ALIAS_TAG:-daily-abliterated}"

usage() {
  cat <<USAGE
Usage:
  ./scripts/download-abliterated-model.sh [--dry-run]
  MODEL_TAG='publisher/model:tag' ./scripts/download-abliterated-model.sh [--dry-run]

Optional env vars:
  MODEL_TAG            Exact Ollama model tag to pull (default: mannix/llama3.1-8b-abliterated:latest)
  OLLAMA_CONTAINER     Docker container name for Ollama (default: chimera-ollama)
  OLLAMA_HOST_URL      Host Ollama URL when running outside Docker (default: http://127.0.0.1:11434)
  RETRIES              Pull retries (default: 3)
  TIMEOUT_S            API probe timeout seconds (default: 30)
  CREATE_ALIAS         true/false, create local alias tag after pull (default: true)
  ALIAS_TAG            Alias name to create (default: daily-abliterated)

Flags:
  --dry-run            Print planned actions only
  -h, --help           Show help
USAGE
}

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg"; usage; exit 1 ;;
  esac
done

log() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*"; exit 1; }

[[ -n "$MODEL_TAG" ]] || fail "MODEL_TAG is required."

# User specifically asked for an abliterated model flow.
if [[ "$MODEL_TAG" != *abliter* ]] && [[ "$MODEL_TAG" != *abliterate* ]]; then
  fail "MODEL_TAG must include 'abliter' or 'abliterate' to avoid pulling the wrong model by mistake."
fi

run_cmd() {
  if $DRY_RUN; then
    echo "[DRYRUN] $*"
  else
    "$@"
  fi
}

have_host_ollama() {
  command -v ollama >/dev/null 2>&1 && curl -fsS --max-time "$TIMEOUT_S" "$OLLAMA_HOST_URL/api/tags" >/dev/null 2>&1
}

have_docker_ollama() {
  command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -Fxq "$OLLAMA_CONTAINER"
}

ollama_exec() {
  if have_host_ollama; then
    run_cmd ollama "$@"
  elif have_docker_ollama; then
    run_cmd docker exec "$OLLAMA_CONTAINER" ollama "$@"
  else
    fail "No reachable Ollama instance found (host or container '$OLLAMA_CONTAINER')."
  fi
}

log "Checking Ollama availability..."
if have_host_ollama; then
  log "Using host Ollama at $OLLAMA_HOST_URL"
elif have_docker_ollama; then
  log "Using Docker Ollama container: $OLLAMA_CONTAINER"
else
  fail "Ollama not detected. Start Ollama first, then retry."
fi

attempt=1
until [[ $attempt -gt $RETRIES ]]; do
  log "Pull attempt $attempt/$RETRIES: $MODEL_TAG"
  if ollama_exec pull "$MODEL_TAG"; then
    log "Model pull completed."
    break
  fi
  if [[ $attempt -eq $RETRIES ]]; then
    fail "Model pull failed after $RETRIES attempts."
  fi
  sleep "$(( attempt * 5 ))"
  attempt=$((attempt + 1))
done

log "Verifying model exists in local Ollama model list..."
if ! ollama_exec list | awk '{print $1}' | grep -Fxq "$MODEL_TAG"; then
  fail "Pull command returned success but model '$MODEL_TAG' was not found in local list."
fi

if [[ "$CREATE_ALIAS" == "true" ]]; then
  log "Creating alias '$ALIAS_TAG' -> '$MODEL_TAG'"
  tmp_modelfile="$(mktemp)"
  cat > "$tmp_modelfile" <<MOD
FROM $MODEL_TAG
PARAMETER temperature 0.6
PARAMETER num_ctx 8192
SYSTEM You are the daily local assistant model for this workstation.
MOD
  if $DRY_RUN; then
    echo "[DRYRUN] ollama create $ALIAS_TAG -f $tmp_modelfile"
  else
    if have_host_ollama; then
      ollama create "$ALIAS_TAG" -f "$tmp_modelfile"
    else
      docker cp "$tmp_modelfile" "$OLLAMA_CONTAINER":/tmp/abliterated.Modelfile
      docker exec "$OLLAMA_CONTAINER" ollama create "$ALIAS_TAG" -f /tmp/abliterated.Modelfile
      docker exec "$OLLAMA_CONTAINER" rm -f /tmp/abliterated.Modelfile
    fi
  fi
  rm -f "$tmp_modelfile"
fi

log "Smoke test inference..."
if ! $DRY_RUN; then
  ollama_exec run "${ALIAS_TAG:-$MODEL_TAG}" "Reply with: READY"
fi

log "Done. Configure Open WebUI model selection to: ${ALIAS_TAG:-$MODEL_TAG}"

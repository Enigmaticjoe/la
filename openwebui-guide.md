# Deploying and Configuring your AI Stack with Open WebUI

This guide walks you through rebuilding your AI stack from scratch on both your **Unraid Brawn** (192.168.1.222) and **Brain PC** (192.168.1.9).  It provides step‑by‑step instructions for downloading models, deploying the Docker stack via Portainer and configuring Open WebUI features like Retrieval‑Augmented Generation (RAG), knowledge bases, built‑in agents and Model Context Protocol (MCP).  The examples assume Unraid’s default file paths (`/mnt/user/appdata/...`) and UID/GID `99:100` as per your environment.  Feel free to adapt the paths if you changed them.

---

## 1 Overview of the AI stack

The stack consists of five services connected on an isolated Docker bridge network:

| Service | Purpose | Ports |
|-------|--------|------|
| **vLLM** | Runs the Large Language Model (LLM) using the [vLLM inference server](https://vllm.ai). It exposes an OpenAI‑compatible `/v1` API used by Open WebUI.  In this configuration the default model is **Dolphin 3.0** (Llama 3.1 base, 8 billion parameters) quantized using AWQ.  This choice fits comfortably in a 12 GB GPU while preserving good reasoning quality. | Host port `8880` → container `8000` |
| **TEI Embedder** | Provides vector embeddings via Hugging Face’s **Text‑Embeddings‑Inference** (TEI).  It runs entirely on CPU and serves a `/v1/embeddings` endpoint.  We use Qwen3‑Embedding‑0.6B, which is supported by TEI ≥ 1.8【986529246581330†L410-L472】. | Host port `8881` → container `80` |
| **TEI Reranker** | Supplies cross‑encoder reranking (scoring) for RAG.  It also uses TEI ≥ 1.8 and the `bge-reranker-large` model, exposing `/rerank`. | Host port `8882` → container `80` |
| **Qdrant** | Vector database used by Open WebUI to store embeddings and enable semantic search.  Qdrant runs on CPU and listens on ports 6333 (HTTP) and 6334 (gRPC). | Host ports `6333`, `6334` |
| **Open WebUI** | The user interface that ties everything together.  It connects to vLLM and TEI via OpenAI‑compatible APIs, indexes documents into Qdrant for RAG and provides advanced features like knowledge bases, web search, pipelines and MCP.  The UI runs on port 3000. | Host port `3000` → container `8080` |

The YAML file `openwebui-stack.yml` defines these services, health‑checks and their inter‑connections on an `ai_grid` network.  The network is auto‑allocated by Docker to avoid IP conflicts with other stacks.

---

## 2 Hardware considerations and model choice

Your RTX 4070 has 12 GB of VRAM, so you need a model that leaves room for the KV cache and context window.  According to the vLLM/Unraid troubleshooting notes, running a 7 – 8 B model in 4‑bit AWQ quantization uses about **5–6 GB** of VRAM, leaving the remainder for the KV cache and system overhead.  Dolphin 3.0 (uncensored, Llama 3.1 base) provides a good balance of quality and memory consumption.  It is served from the `solidrust/dolphin-3.0-llama3.1-8b-AWQ` repository with Marlin kernels for fast inference.  You can later add other models (e.g., Qwen2.5 7B AWQ) by editing both the download script and the YAML file.

---

## 3 Preparing the models

### 3.1 Directory structure

Create the following directories on both Unraid and Brain PC.  They will store the downloaded models and Hugging Face cache:

```bash
sudo mkdir -p /mnt/user/appdata/huggingface/ \
    /mnt/user/appdata/huggingface/vllm-models \
    /mnt/user/appdata/huggingface/tei-embed-data \
    /mnt/user/appdata/huggingface/tei-rerank-data \
    /mnt/user/appdata/huggingface/hub
sudo chown -R 99:100 /mnt/user/appdata/huggingface
sudo chmod -R 755 /mnt/user/appdata/huggingface
```

These paths mirror the volumes defined in `openwebui-stack.yml`, ensuring that the containers see the correct files.

### 3.2 Run the model downloader script

The `ai-model-downloader.sh` script automates downloading all required models using a disposable Python container.  It avoids the `huggingface-cli` issues described in your earlier logs by using `python -m huggingface_hub` inside the container.  Here is the complete script:

```bash
#!/bin/bash
set -euo pipefail

# Base directories (adjust if you changed your Unraid paths)
BASE_DIR="/mnt/user/appdata/huggingface"
VLLM_MODELS="${BASE_DIR}/vllm-models"
TEI_EMBED_DATA="${BASE_DIR}/tei-embed-data"
TEI_RERANK_DATA="${BASE_DIR}/tei-rerank-data"
HF_CACHE="${BASE_DIR}/hub"

# List of vLLM model IDs to download.  Dolphin 3.0 is included by default.  Add
# or comment out models as needed.  AWQ models are strongly recommended for
# 12 GB GPUs.
VLLM_MODELS_LIST=(
  "solidrust/dolphin-3.0-llama3.1-8b-AWQ"
  # "solidrust/dolphin-2.9.4-llama3.1-8b-AWQ"
  # "Qwen/Qwen2.5-7B-Instruct-AWQ"
)

# Embedding and reranker model IDs (compatible with TEI ≥ 1.8)
TEI_EMBED_MODEL="Qwen/Qwen3-Embedding-0.6B"
TEI_RERANK_MODEL="BAAI/bge-reranker-large"

# Pull a slim Python image to run the downloads
DOCKER_IMAGE="python:3.11-slim"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

mkdir -p "$VLLM_MODELS" "$TEI_EMBED_DATA" "$TEI_RERANK_DATA" "$HF_CACHE"
chown -R 99:100 "$BASE_DIR"; chmod -R 755 "$BASE_DIR"

log "Pulling Docker image $DOCKER_IMAGE…"
docker pull "$DOCKER_IMAGE" >/dev/null

download_model() {
  local model_id=$1
  local dest_dir=$2
  if [ -d "$dest_dir/$model_id" ] && [ "$(ls -A "$dest_dir/$model_id" 2>/dev/null)" ]; then
    log "SKIP: $model_id already exists"
    return
  fi
  log "Downloading $model_id…"
  docker run --rm \
    -v "$dest_dir:/data" \
    -v "$HF_CACHE:/root/.cache/huggingface" \
    -e HF_HUB_ENABLE_HF_TRANSFER=1 \
    "$DOCKER_IMAGE" bash -c "pip install -q huggingface_hub hf_transfer && \
      python3 - <<'PY'
import os, sys
from huggingface_hub import snapshot_download
model = os.environ['MODEL_ID']
dest  = f"/data/{model}"
print(f'Downloading {model} → {dest}')
snapshot_download(repo_id=model, local_dir=dest, local_dir_use_symlinks=False, resume_download=True)
PY""
}

# Download vLLM models
for model in "${VLLM_MODELS_LIST[@]}"; do
  download_model "$model" "$VLLM_MODELS"
done

# Download embedding and reranker models
download_model "$TEI_EMBED_MODEL" "$TEI_EMBED_DATA"
download_model "$TEI_RERANK_MODEL" "$TEI_RERANK_DATA"

log "All models downloaded.  Ready for stack deployment."
```

Save the script as `/boot/config/plugins/user.scripts/scripts/ai-model-downloader.sh` (Unraid user scripts location) or to any directory on your Brain PC.  Run it from a terminal before deploying the stack:

```bash
chmod +x ai-model-downloader.sh
./ai-model-downloader.sh
```

This will pull the Python image, download each model and set the correct permissions (`99:100`) so that Unraid can read them.  The script safely skips models that are already downloaded, allowing you to add additional models later without re‑downloading everything.

---

## 4 Deploying the stack in Portainer

1. **Log into Portainer** on your Unraid server (http://192.168.1.222:9000/ if you used the default port).
2. Navigate to **Stacks → Add Stack**.
3. Name the stack (e.g., `openwebui`) and paste the contents of `openwebui-stack.yml` into the editor.  A copy of this file is included separately for convenience.
4. Modify the following environment variables in the YAML before deploying:
   - `WEBUI_SECRET_KEY`: set this to a long, random string.  Open WebUI requires a secret key for encrypting OAuth tokens and is a prerequisite for MCP【58929462695763†L82-L88】.
   - `WEBUI_AUTH`: leave as `False` for single‑user mode.  If you want multi‑user authentication later, set it to `True` and enable sign‑up in the Admin Panel.
   - `ENABLE_PERSISTENT_CONFIG`: keep `false` initially.  This forces Open WebUI to read environment variables on each restart.  When you’re satisfied with your settings, you can enable persistent config via Admin Settings.
5. Click **Deploy the Stack**.  Docker will pull all images and start the containers.  It may take a few minutes the first time as vLLM warms up.  You can monitor progress under **Containers**.

Once running, access Open WebUI at http://192.168.1.222:3000.  Since `WEBUI_AUTH` is disabled, you’ll drop straight into the chat interface.  OpenAI keys are not required because you are using your own local inference services.

### Brain PC deployment

To run a second copy of the stack on your Brain PC (192.168.1.9), repeat the same steps.  The only differences are:

1. **Model downloads**: run the model downloader on the Brain PC so that the models exist at `/mnt/user/appdata/huggingface/...` on that machine.  Alternatively, you can mount the Unraid share via NFS/SMB and re‑use the models.
2. **Ports**: ensure the host ports do not conflict with other services running on your PC.  For example, you might map vLLM to `8890:8000`, TEI embed to `8891:80`, and so on.  Adjust the `ports` section of the YAML accordingly.
3. **Cross‑system usage**: If you want the Brain PC’s Open WebUI to use the Unraid server’s vLLM (for heavier workloads) while still running the UI locally, set `OPENAI_API_BASE_URL=http://192.168.1.222:8880/v1` in the Brain PC’s `open-webui` service.  Similarly, you can point its RAG variables (`RAG_OPENAI_API_BASE_URL`, `RAG_EXTERNAL_RERANKER_URL` and `QDRANT_URL`) to the Unraid endpoints.  For example:

```yaml
environment:
  - OPENAI_API_BASE_URL=http://192.168.1.222:8880/v1
  - RAG_OPENAI_API_BASE_URL=http://192.168.1.222:8881/v1
  - RAG_EXTERNAL_RERANKER_URL=http://192.168.1.222:8882/rerank
  - QDRANT_URL=http://192.168.1.222:6333
```

This lets the lightweight Brain PC UI leverage the heavy inference workloads on Unraid while still maintaining a responsive local interface.

---

## 5 Using Open WebUI

### 5.1 RAG and embeddings

Open WebUI supports Retrieval‑Augmented Generation (RAG) by combining its knowledge bases, your documents and the web.  The environment variables in the YAML configure RAG to use your local TEI embedder and reranker instead of paid OpenAI endpoints:

* `RAG_OPENAI_API_BASE_URL` points to the TEI embedder’s `/v1` endpoint (http://tei-embed:80/v1).  According to Open WebUI’s docs, this tells the system where to send embedding requests【212468990885291†L3281-L3294】.
* `RAG_EXTERNAL_RERANKER_URL` specifies the full URL of the reranking service.  The docs emphasise that the full path (e.g., `/rerank`) must be included【212468990885291†L3370-L3381】.
* `ENABLE_QUERIES_CACHE` is enabled to cache LLM‑generated search queries, reducing duplicate calls when both web search and RAG are active【212468990885291†L3399-L3408】.

With these variables set, the system will automatically embed your queries and documents using Qwen3‑Embedding and rerank candidates with BGE‑Reranker before passing the results to your LLM.  You can tune the RAG behaviour from **Admin Settings → RAG** in the UI.

### 5.2 Knowledge bases

The **Knowledge** section in Open WebUI acts like a persistent memory.  It stores structured information (notes, policies, reference documents) that you can recall in chats.  You don’t need coding expertise; simply navigate to **Workspace → Knowledge** and start adding entries【242780897830315†L91-L104】.  Examples include project parameters, commands or personal preferences【242780897830315†L111-L118】.  To reference knowledge in a chat, prepend the saved item’s name with `#`, and the model will automatically include it in context【242780897830315†L121-L133】.

When running in **agentic mode**, high‑quality models can autonomously search and read from knowledge bases using built‑in tools like `query_knowledge_bases`, `list_knowledge_bases`, `search_knowledge_bases`, `search_knowledge_files` and `view_knowledge_file`【242780897830315†L151-L160】.  These functions allow the model to explore stored documents on its own, making conversations more contextually aware.  Smaller local models may need manual prompting to achieve the same effect.

### 5.3 Web search

Web search is enabled via `ENABLE_WEB_SEARCH=true` and uses the Searx engine by default.  You can change `SEARCH_PROVIDER` to other providers (e.g., `ddg` or `google`) from the Admin panel.  Search queries are generated automatically, but you can disable query generation or caching via the environment variables `ENABLE_RETRIEVAL_QUERY_GENERATION` and `ENABLE_QUERIES_CACHE`【212468990885291†L3391-L3408】.

### 5.4 Tools and functions

Open WebUI allows you to extend the model’s abilities through **Tools** and the UI’s capabilities through **Functions**【417905171035795†L104-L159】.  Tools act like plugins that retrieve external data (e.g., weather, stock prices), while functions add new features or buttons to the UI itself.  You can explore and install community‑contributed tools/functions via **Admin → Tools & Functions**.  Pipelines are an advanced feature for building API‑compatible workflows【417905171035795†L185-L206】; most users won’t need them unless offloading processing to separate servers.

### 5.5 Model Context Protocol (MCP)

MCP enables streaming communications between your LLM and external services.  To use MCP you **must** set `WEBUI_SECRET_KEY` in your environment【58929462695763†L82-L88】.  After deploying the stack:

1. Open **Admin Settings → External Tools**.
2. Click **+ Add Server**.
3. Set **Type** to **MCP (Streamable HTTP)** and enter the server URL and authentication details【58929462695763†L89-L105】.  Make sure you select *MCP*, not *OpenAPI*, otherwise the UI will crash【58929462695763†L99-L106】.
4. For local servers running outside of Docker, use `http://host.docker.internal:<port>` instead of `localhost`【58929462695763†L157-L162】.
5. Leave **Function Name Filter List** empty to expose all tools, or add a comma (`,`) if you encounter parsing bugs【58929462695763†L165-L170】.

This setup allows the LLM to call custom MCP tools (e.g., scrapers, ingestion pipelines) with streaming responses.  For most everyday integrations, however, OpenAPI remains the recommended approach【58929462695763†L111-L123】.

---

## 6 Maintenance and automation

### 6.1 Health‑check script (optional)

You can create a simple script to verify that each service is up and responding after deployment.  Save the following as `ai-stack-healthcheck.sh` and run it from any machine on your LAN:

```bash
#!/bin/bash
set -e
BASE="http://192.168.1.222"  # change to 192.168.1.9 to check your Brain PC

echo "Checking vLLM…"
curl -sf "$BASE:8880/health" && echo "  vLLM OK" || echo "  vLLM DOWN"

echo "Checking TEI embedder…"
curl -sf "$BASE:8881/health" && echo "  TEI embed OK" || echo "  TEI embed DOWN"

echo "Checking TEI reranker…"
curl -sf "$BASE:8882/health" && echo "  Reranker OK" || echo "  Reranker DOWN"

echo "Checking Qdrant…"
curl -sf "$BASE:6333/health" && echo "  Qdrant OK" || echo "  Qdrant DOWN"

echo "Checking Open WebUI…"
curl -sf "$BASE:3000" && echo "  WebUI OK" || echo "  WebUI DOWN"
```

Make it executable with `chmod +x ai-stack-healthcheck.sh` and run it after you start the stack.

### 6.2 Adding new models

To experiment with other models, add the model’s Hugging Face ID to the `VLLM_MODELS_LIST` array in `ai-model-downloader.sh`, rerun the script, and then modify the `--model` and `--served-model-name` parameters in `openwebui-stack.yml`.  Redeploy the stack via Portainer.  You can keep multiple models downloaded and simply switch between them by changing the path and served name.

### 6.3 Upgrading TEI or Open WebUI

The TEI images in the YAML use the `1.8` tag because Qwen3 embeddings require support added in that release【986529246581330†L410-L472】.  To upgrade later, change the tag (e.g., `1.9`) in the YAML and redeploy.  For Open WebUI, use the `main` tag for the latest stable release or `cuda` for GPU‑accelerated image editing.

---

## 7 Troubleshooting

* **Health check failures** – If Portainer reports a container as unhealthy, click the container name and view its logs.  Common issues include missing model files, wrong model paths or unsupported architectures.  Ensure that your TEI image tag matches the models you downloaded (≥ 1.8 for Qwen3) and that the directory structure under `/mnt/user/appdata/huggingface` matches the `--model-id` paths.
* **Stack deployment errors** – If Portainer returns an IPAM conflict (e.g., “pool overlaps with other one on this address space”), remove the custom `ipam` section from the YAML.  The provided `openwebui-stack.yml` already relies on Docker’s automatic subnet allocation to avoid such clashes.
* **Missing changes after editing environment variables** – Persistent config variables remain in the database after the first run.  To force the system to read new environment variables, either set `ENABLE_PERSISTENT_CONFIG=false` (as in the YAML)【212468990885291†L67-L99】 or update the setting directly in the Admin UI.  Only remove the volume (`docker volume rm open-webui`) as a last resort【212468990885291†L131-L141】.
* **MCP connection errors** – If you add an external tool but the chat shows “Failed to connect to MCP server,” double‑check that you chose **MCP (Streamable HTTP)** as the connection type and that you selected the correct authentication mode.  Leaving the **Bearer** fields blank may send an empty authorization header【58929462695763†L144-L151】.

---

## 8 Conclusion

By following this guide you have rebuilt your AI stack with up‑to‑date components and optimised it for your Unraid and Portainer environment.  Dolphin 3.0 provides powerful reasoning without exceeding your 12 GB VRAM budget, TEI handles embeddings and reranking entirely on CPU and Open WebUI ties everything together with RAG, knowledge bases, web search, tools and MCP.  Use this foundation to explore new models, integrate your own tools via MCP or OpenAPI, and experiment with the growing ecosystem of Open WebUI functions.  Happy hacking!
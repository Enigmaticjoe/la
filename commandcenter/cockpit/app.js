const endpoints = {
  ollama: window.CHIMERA_OLLAMA_URL || "http://localhost:11434",
  portainer: window.CHIMERA_PORTAINER_URL || "https://localhost:9443",
  webui: window.CHIMERA_WEBUI_URL || "http://localhost:3000",
  qdrant: window.CHIMERA_QDRANT_URL || "http://localhost:6333",
};

const links = [
  ["Portainer", endpoints.portainer],
  ["Open WebUI", endpoints.webui],
  ["Ollama API", endpoints.ollama],
  ["Qdrant", endpoints.qdrant],
  ["Grafana", "http://localhost:3002"],
  ["Prometheus", "http://localhost:9090"],
  ["SearXNG", "http://localhost:8080"],
  ["Home Assistant", "http://localhost:8123"],
];

const statusMap = [
  ["brain-state", `${endpoints.ollama}/api/tags`],
  ["portainer-state", endpoints.portainer],
  ["webui-state", endpoints.webui],
  ["qdrant-state", `${endpoints.qdrant}/collections`],
];

function writeConstellation(text) {
  const el = document.getElementById("constellation");
  const dot = document.createElement("div");
  dot.className = "star-text";
  dot.style.left = `${Math.random() * 80 + 5}%`;
  dot.style.top = `${Math.random() * 82 + 6}%`;
  dot.textContent = text.slice(0, 28);
  el.appendChild(dot);
  if (el.children.length > 22) el.removeChild(el.firstChild);
}

async function probe(url, id) {
  const target = document.getElementById(id);
  try {
    await fetch(url, { method: "GET", mode: "no-cors" });
    target.textContent = "ONLINE";
    target.style.color = "#00f5a0";
  } catch {
    target.textContent = "UNREACHABLE";
    target.style.color = "#ff7a7a";
  }
}

async function refreshStatus() {
  document.getElementById("mode").textContent = "SCANNING";
  await Promise.all(statusMap.map(([id, url]) => probe(url, id)));
  document.getElementById("mode").textContent = "ACTIVE";
}

function buildLinks() {
  const root = document.getElementById("service-links");
  links.forEach(([name, url]) => {
    const a = document.createElement("a");
    a.href = url;
    a.target = "_blank";
    a.rel = "noreferrer noopener";
    a.textContent = name;
    root.appendChild(a);
  });
}

async function sendChat(event) {
  event.preventDefault();
  const input = document.getElementById("chat-input");
  const prompt = input.value.trim();
  if (!prompt) return;
  appendMessage("user", `> ${prompt}`);
  input.value = "";

  try {
    const res = await fetch(`${endpoints.ollama}/api/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ model: "llama3.2", prompt, stream: false }),
    });
    const data = await res.json();
    const reply = data.response || "No response payload received.";
    appendMessage("bot", reply);
    writeConstellation(reply);
  } catch (error) {
    appendMessage("bot", `Local AI call failed: ${error.message}`);
  }
}

function appendMessage(type, text) {
  const log = document.getElementById("chat-log");
  const div = document.createElement("div");
  div.className = `msg ${type}`;
  div.textContent = text;
  log.appendChild(div);
  log.scrollTop = log.scrollHeight;
}

document.getElementById("chat-form").addEventListener("submit", sendChat);
document.getElementById("refresh-status").addEventListener("click", refreshStatus);
buildLinks();
refreshStatus();
writeConstellation("ORBIT LINK READY");

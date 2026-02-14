const services = [
  { name: 'Portainer', url: 'https://localhost:9443' },
  { name: 'Open WebUI', url: 'http://localhost:8080' },
  { name: 'Ollama API', url: 'http://localhost:11434' },
  { name: 'Qdrant', url: 'http://localhost:6333/dashboard' },
  { name: 'Cloudflared Logs', url: 'http://localhost:9000' }
];

const serviceButtons = document.getElementById('serviceButtons');
services.forEach((svc) => {
  const a = document.createElement('a');
  a.className = 'launch';
  a.href = svc.url;
  a.target = '_blank';
  a.rel = 'noreferrer noopener';
  a.textContent = svc.name;
  serviceButtons.appendChild(a);
});

function updateReadouts() {
  document.getElementById('cpuVal').textContent = `${Math.floor(30 + Math.random() * 45)}%`;
  document.getElementById('ramVal').textContent = `${Math.floor(40 + Math.random() * 40)}%`;
  document.getElementById('ctrVal').textContent = `${Math.floor(6 + Math.random() * 8)}`;
}
setInterval(updateReadouts, 1700);
updateReadouts();

const chatLog = document.getElementById('chatLog');
const chatForm = document.getElementById('chatForm');
const promptInput = document.getElementById('prompt');

function appendMessage(role, msg) {
  const p = document.createElement('p');
  p.innerHTML = `<strong>${role}:</strong> ${msg}`;
  chatLog.appendChild(p);
  chatLog.scrollTop = chatLog.scrollHeight;
}

chatForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const prompt = promptInput.value.trim();
  if (!prompt) return;
  promptInput.value = '';
  appendMessage('YOU', prompt);

  try {
    const res = await fetch('http://localhost:8080/api/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'llama3.1',
        messages: [{ role: 'user', content: prompt }],
        stream: false
      })
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    const msg = data?.choices?.[0]?.message?.content ?? 'No response payload.';
    appendMessage('AI', msg);
    document.getElementById('constellationText').textContent = `CONSTELLATION FEED: ${msg.slice(0, 96)}`;
  } catch (err) {
    appendMessage('SYS', `Local AI unavailable (${err.message}). Open Open WebUI and confirm model availability.`);
  }
});

const canvas = document.getElementById('portal');
const ctx = canvas.getContext('2d');
let t = 0;

function drawPortal() {
  ctx.fillStyle = 'rgba(0, 8, 20, 0.35)';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  for (let i = 0; i < 60; i++) {
    const x = (Math.sin(i * 7 + t / 25) * 120 + 180 + i * 3) % canvas.width;
    const y = (Math.cos(i * 11 + t / 35) * 80 + 110 + i * 2) % canvas.height;
    ctx.fillStyle = `rgba(180,220,255,${0.3 + (i % 5) / 6})`;
    ctx.beginPath();
    ctx.arc(x, y, (i % 3) + 0.7, 0, Math.PI * 2);
    ctx.fill();
    if (i % 8 === 0) {
      ctx.strokeStyle = 'rgba(90,190,255,0.35)';
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo((x + 30) % canvas.width, (y + 15) % canvas.height);
      ctx.stroke();
    }
  }
  t += 1;
  requestAnimationFrame(drawPortal);
}
drawPortal();

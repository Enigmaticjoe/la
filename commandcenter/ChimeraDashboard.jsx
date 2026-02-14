import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  Brain,
  Monitor,
  Search as SearchIcon,
  Download,
  Activity,
  Cog,
  Terminal,
} from "lucide-react";
import { motion } from "framer-motion";

const services = [
  {
    name: "Brain (LLM)",
    description:
      "Local language model server using your Intel Arc A770. Chat with uncensored models on your own hardware.",
    url: "http://localhost:11434",
    icon: Brain,
  },
  {
    name: "Face (Open WebUI)",
    description:
      "Graphical chat interface connected to your local LLM brain. Supports custom personas and file uploads.",
    url: "http://localhost:11435",
    icon: Activity,
  },
  {
    name: "Research (Search)",
    description:
      "Privacy‑respecting metasearch engine powered by SearXNG. Explore the internet without tracking.",
    url: "http://localhost:8080",
    icon: SearchIcon,
  },
  {
    name: "Torrent & VPN",
    description:
      "qBittorrent with Mullvad WireGuard running in a container. Download freely through a secure tunnel.",
    url: "http://localhost:8112",
    icon: Download,
  },
  {
    name: "Monitor",
    description:
      "System and service dashboards (Grafana/Prometheus) to watch your CPU, GPU, and container health.",
    url: "http://localhost:3001",
    icon: Monitor,
  },
  {
    name: "Portainer",
    description:
      "Visual container management interface to control brain, brawn and edge services.",
    url: "https://localhost:9443",
    icon: Cog,
  },
  {
    name: "Kali GPT (Cyber Assistant)",
    description:
      "Hacker‑style AI assistant trained on penetration testing manuals and exploit write‑ups. Use responsibly.",
    url: "http://localhost:11435/?preset=kali-gpt",
    icon: Terminal,
  },
];

export default function Dashboard() {
  return (
    <div className="bg-black text-gray-100 min-h-screen flex flex-col font-mono">
      <header className="p-6 border-b border-gray-700">
        <h1 className="text-3xl font-bold tracking-tight text-green-400">
          Project Chimera Command Center
        </h1>
        <p className="text-sm text-gray-500 mt-1">
          Welcome, operator. Choose a module below to engage.
        </p>
      </header>
      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar Navigation */}
        <aside className="w-64 bg-gray-900 border-r border-gray-700 p-4 overflow-y-auto hidden lg:block">
          <nav className="space-y-2">
            {services.map((service) => (
              <a
                key={service.name}
                href={`#${service.name.toLowerCase().replace(/\s+/g, "-")}`}
                className="flex items-center space-x-2 py-2 px-3 rounded hover:bg-gray-800 transition-colors"
              >
                <service.icon className="w-4 h-4" />
                <span className="truncate">{service.name}</span>
              </a>
            ))}
          </nav>
        </aside>
        {/* Main Content */}
        <main className="flex-1 overflow-y-auto p-6 space-y-8">
          {services.map((service) => (
            <motion.div
              key={service.name}
              id={service.name.toLowerCase().replace(/\s+/g, "-")}
              className="rounded-xl border border-gray-700 p-6 bg-gray-900"
              whileHover={{ scale: 1.02, boxShadow: "0 0 15px 0 rgba(0,255,150,0.4)" }}
              transition={{ duration: 0.3 }}
            >
              <h2 className="text-xl font-semibold flex items-center space-x-2 text-green-300">
                <service.icon className="w-5 h-5" />
                <span>{service.name}</span>
              </h2>
              <p className="mt-2 text-sm text-gray-400">
                {service.description}
              </p>
              <div className="mt-4">
                <Button asChild>
                  <a
                    href={service.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="w-full"
                  >
                    Launch
                  </a>
                </Button>
              </div>
            </motion.div>
          ))}
        </main>
      </div>
    </div>
  );
}

// Brain AI System Dashboard Configuration

const CONFIG = {
  // Service endpoints - Update these with your actual service IPs/ports
  services: [
    {
      id: 'vllm',
      name: 'vLLM Inference',
      icon: '🤖',
      endpoint: 'http://10.111.222.41:8000/health',
      url: 'http://10.111.222.41:8000',
      description: 'Large Language Model Inference Engine',
      type: 'critical'
    },
    {
      id: 'qdrant',
      name: 'Qdrant Vector DB',
      icon: '🗄️',
      endpoint: 'http://10.111.222.41:6333/health',
      url: 'http://10.111.222.41:6333/dashboard',
      description: 'Vector Database for Embeddings',
      type: 'critical'
    },
    {
      id: 'embeddings',
      name: 'Embeddings Service',
      icon: '🔢',
      endpoint: 'http://10.111.222.41:11434/api/tags',
      url: 'http://10.111.222.41:11434',
      description: 'Text Embedding Generation',
      type: 'critical'
    },
    {
      id: 'searxng',
      name: 'SearXNG Search',
      icon: '🔍',
      endpoint: 'http://10.111.222.41:8080/healthz',
      url: 'http://10.111.222.41:8080',
      description: 'Privacy-Focused Search Engine',
      type: 'optional'
    },
    {
      id: 'openwebui',
      name: 'Open WebUI',
      icon: '🌐',
      endpoint: 'http://10.111.222.41:3000/api/health',
      url: 'http://10.111.222.41:3000',
      description: 'Web Interface for AI Interactions',
      type: 'critical'
    },
    {
      id: 'coding-agent',
      name: 'Coding Agent',
      icon: '💻',
      endpoint: 'http://10.111.222.41:8001/health',
      url: 'http://10.111.222.41:8001',
      description: 'AI-Powered Code Assistant',
      type: 'optional'
    },
    {
      id: 'hardware-agent',
      name: 'Hardware Agent',
      icon: '🖥️',
      endpoint: 'http://10.111.222.41:8002/health',
      url: 'http://10.111.222.41:8002',
      description: 'System Hardware Monitoring',
      type: 'optional'
    }
  ],

  // Metrics endpoints
  metrics: {
    gpu: 'http://10.111.222.41:8002/api/gpu',
    system: 'http://10.111.222.41:8002/api/system',
    stats: 'http://10.111.222.41:8002/api/stats'
  },

  // Refresh intervals (milliseconds)
  refreshIntervals: {
    services: 5000,      // 5 seconds
    metrics: 5000,       // 5 seconds
    systemInfo: 30000    // 30 seconds
  },

  // Alert thresholds
  thresholds: {
    gpuTemp: {
      warning: 75,
      critical: 85
    },
    vramUsage: {
      warning: 80,
      critical: 95
    },
    cpuUsage: {
      warning: 80,
      critical: 95
    },
    ramUsage: {
      warning: 85,
      critical: 95
    }
  },

  // Theme settings
  theme: {
    primaryColor: '#00ff9f',
    secondaryColor: '#00d4ff',
    dangerColor: '#ff006e',
    warningColor: '#ffbe0b',
    successColor: '#00ff9f',
    bgDark: '#0a0e27',
    bgCard: 'rgba(15, 23, 42, 0.8)'
  },

  // Feature flags
  features: {
    autoRefresh: true,
    soundAlerts: false,
    animations: true,
    detailedMetrics: true
  },

  // Fallback/mock data for development
  useMockData: false,

  // API timeout (milliseconds)
  apiTimeout: 5000
};

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CONFIG;
}

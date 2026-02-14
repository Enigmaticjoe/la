// Brain AI System Dashboard - Main Application Logic

class DashboardApp {
  constructor() {
    this.config = CONFIG;
    this.servicesData = new Map();
    this.metricsData = {};
    this.refreshTimers = {};
    this.isInitialized = false;
    
    this.init();
  }

  init() {
    console.log('🧠 Initializing Brain AI Dashboard...');
    
    // Set up event listeners
    this.setupEventListeners();
    
    // Initialize UI
    this.updateTime();
    this.renderServices();
    
    // Start data refresh cycles
    if (this.config.features.autoRefresh) {
      this.startAutoRefresh();
    }
    
    // Initial data fetch
    this.refreshAll();
    
    this.isInitialized = true;
    console.log('✅ Dashboard initialized successfully');
  }

  setupEventListeners() {
    // Manual refresh button
    const refreshBtn = document.getElementById('manualRefresh');
    if (refreshBtn) {
      refreshBtn.addEventListener('click', () => this.refreshAll());
    }

    // Update time every second
    setInterval(() => this.updateTime(), 1000);
  }

  updateTime() {
    const timeElement = document.getElementById('currentTime');
    if (timeElement) {
      const now = new Date();
      timeElement.textContent = now.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
      });
    }
  }

  renderServices() {
    const container = document.getElementById('servicesGrid');
    if (!container) return;

    container.innerHTML = '';

    this.config.services.forEach(service => {
      const card = this.createServiceCard(service);
      container.appendChild(card);
    });
  }

  createServiceCard(service) {
    const card = document.createElement('div');
    card.className = 'service-card slide-up';
    card.id = `service-${service.id}`;

    card.innerHTML = `
      <div class="service-header">
        <div class="service-title-group">
          <div class="service-icon">${service.icon}</div>
          <div class="service-name">${service.name}</div>
        </div>
        <div class="service-status" id="status-${service.id}">
          <span class="loading"></span>
        </div>
      </div>
      <div class="service-description">${service.description}</div>
      <div class="service-metrics" id="metrics-${service.id}">
        <div class="service-metric">
          <div class="service-metric-label">Latency</div>
          <div class="service-metric-value" id="latency-${service.id}">--ms</div>
        </div>
        <div class="service-metric">
          <div class="service-metric-label">Status</div>
          <div class="service-metric-value" id="uptime-${service.id}">--</div>
        </div>
      </div>
      <a href="${service.url}" target="_blank" class="service-link" id="link-${service.id}">
        Open Service →
      </a>
    `;

    return card;
  }

  async refreshAll() {
    console.log('🔄 Refreshing all data...');
    
    const refreshBtn = document.getElementById('manualRefresh');
    if (refreshBtn) {
      refreshBtn.disabled = true;
      refreshBtn.querySelector('.refresh-icon').style.transform = 'rotate(360deg)';
    }

    await Promise.all([
      this.fetchAllServices(),
      this.fetchMetrics()
    ]);

    this.updateLastRefreshTime();

    setTimeout(() => {
      if (refreshBtn) {
        refreshBtn.disabled = false;
        refreshBtn.querySelector('.refresh-icon').style.transform = 'rotate(0deg)';
      }
    }, 1000);
  }

  async fetchAllServices() {
    const promises = this.config.services.map(service => 
      this.checkServiceHealth(service)
    );

    await Promise.allSettled(promises);
    this.updateServicesCount();
  }

  async checkServiceHealth(service) {
    const startTime = Date.now();
    const statusElement = document.getElementById(`status-${service.id}`);
    const latencyElement = document.getElementById(`latency-${service.id}`);
    const uptimeElement = document.getElementById(`uptime-${service.id}`);

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.config.apiTimeout);

      const response = await fetch(service.endpoint, {
        method: 'GET',
        signal: controller.signal,
        mode: 'cors',
        cache: 'no-cache'
      });

      clearTimeout(timeoutId);
      const latency = Date.now() - startTime;

      if (response.ok) {
        this.updateServiceStatus(service.id, 'online', latency);
        if (latencyElement) latencyElement.textContent = `${latency}ms`;
        if (uptimeElement) uptimeElement.textContent = 'Healthy';
      } else {
        this.updateServiceStatus(service.id, 'degraded', latency);
        if (uptimeElement) uptimeElement.textContent = 'Degraded';
      }
    } catch (error) {
      console.warn(`Service ${service.name} check failed:`, error.message);
      this.updateServiceStatus(service.id, 'offline', null);
      if (latencyElement) latencyElement.textContent = '--';
      if (uptimeElement) uptimeElement.textContent = 'Offline';
      
      // Add alert for critical services
      if (service.type === 'critical') {
        this.addAlert('danger', `${service.name} is offline`);
      }
    }
  }

  updateServiceStatus(serviceId, status, latency) {
    const statusElement = document.getElementById(`status-${serviceId}`);
    if (!statusElement) return;

    const statusText = status.toUpperCase();
    const statusClass = `service-status ${status}`;
    
    statusElement.className = statusClass;
    statusElement.innerHTML = statusText;

    // Store service data
    this.servicesData.set(serviceId, { status, latency });
  }

  async fetchMetrics() {
    // Fetch GPU metrics
    await this.fetchGPUMetrics();
    
    // Fetch system metrics
    await this.fetchSystemMetrics();
    
    // Update system info
    this.updateSystemInfo();
  }

  async fetchGPUMetrics() {
    try {
      // Mock data for development/fallback
      const mockGPU = {
        temperature: Math.floor(Math.random() * 30) + 60, // 60-90°C
        vramUsed: Math.floor(Math.random() * 8) + 8, // 8-16 GB
        vramTotal: 24
      };

      // Try to fetch real data
      let gpuData = mockGPU;
      
      if (!this.config.useMockData) {
        try {
          const response = await fetch(this.config.metrics.gpu, {
            signal: AbortSignal.timeout(this.config.apiTimeout)
          });
          if (response.ok) {
            gpuData = await response.json();
          }
        } catch (e) {
          console.warn('Using mock GPU data:', e.message);
        }
      }

      // Update GPU temperature
      const gpuTemp = gpuData.temperature || mockGPU.temperature;
      const tempElement = document.getElementById('gpuTemp');
      const tempBar = document.getElementById('gpuTempBar');
      
      if (tempElement) tempElement.textContent = `${gpuTemp}°C`;
      if (tempBar) {
        const tempPercent = Math.min((gpuTemp / 100) * 100, 100);
        tempBar.style.width = `${tempPercent}%`;
        
        // Change color based on threshold
        if (gpuTemp >= this.config.thresholds.gpuTemp.critical) {
          tempBar.style.background = `linear-gradient(90deg, ${this.config.theme.dangerColor}, #ff4500)`;
          this.addAlert('danger', `GPU temperature critical: ${gpuTemp}°C`);
        } else if (gpuTemp >= this.config.thresholds.gpuTemp.warning) {
          tempBar.style.background = `linear-gradient(90deg, ${this.config.theme.warningColor}, #ffa500)`;
        }
      }

      // Update VRAM
      const vramUsed = gpuData.vramUsed || mockGPU.vramUsed;
      const vramTotal = gpuData.vramTotal || mockGPU.vramTotal;
      const vramElement = document.getElementById('vramUsage');
      const vramBar = document.getElementById('vramBar');
      
      if (vramElement) vramElement.textContent = `${vramUsed} / ${vramTotal} GB`;
      if (vramBar) {
        const vramPercent = (vramUsed / vramTotal) * 100;
        vramBar.style.width = `${vramPercent}%`;
        
        if (vramPercent >= this.config.thresholds.vramUsage.critical) {
          vramBar.style.background = `linear-gradient(90deg, ${this.config.theme.dangerColor}, #ff4500)`;
          this.addAlert('danger', `VRAM usage critical: ${vramPercent.toFixed(1)}%`);
        } else if (vramPercent >= this.config.thresholds.vramUsage.warning) {
          vramBar.style.background = `linear-gradient(90deg, ${this.config.theme.warningColor}, #ffa500)`;
        }
      }

    } catch (error) {
      console.error('Error fetching GPU metrics:', error);
    }
  }

  async fetchSystemMetrics() {
    try {
      // Mock data for development/fallback
      const mockSystem = {
        cpu: Math.floor(Math.random() * 40) + 20, // 20-60%
        ramUsed: Math.floor(Math.random() * 16) + 16, // 16-32 GB
        ramTotal: 64
      };

      let systemData = mockSystem;
      
      if (!this.config.useMockData) {
        try {
          const response = await fetch(this.config.metrics.system, {
            signal: AbortSignal.timeout(this.config.apiTimeout)
          });
          if (response.ok) {
            systemData = await response.json();
          }
        } catch (e) {
          console.warn('Using mock system data:', e.message);
        }
      }

      // Update CPU
      const cpuUsage = systemData.cpu || mockSystem.cpu;
      const cpuElement = document.getElementById('cpuUsage');
      const cpuBar = document.getElementById('cpuBar');
      
      if (cpuElement) cpuElement.textContent = `${cpuUsage}%`;
      if (cpuBar) {
        cpuBar.style.width = `${cpuUsage}%`;
        
        if (cpuUsage >= this.config.thresholds.cpuUsage.critical) {
          cpuBar.style.background = `linear-gradient(90deg, ${this.config.theme.dangerColor}, #ff4500)`;
        } else if (cpuUsage >= this.config.thresholds.cpuUsage.warning) {
          cpuBar.style.background = `linear-gradient(90deg, ${this.config.theme.warningColor}, #ffa500)`;
        }
      }

      // Update RAM
      const ramUsed = systemData.ramUsed || mockSystem.ramUsed;
      const ramTotal = systemData.ramTotal || mockSystem.ramTotal;
      const ramElement = document.getElementById('ramUsage');
      const ramBar = document.getElementById('ramBar');
      
      if (ramElement) ramElement.textContent = `${ramUsed} / ${ramTotal} GB`;
      if (ramBar) {
        const ramPercent = (ramUsed / ramTotal) * 100;
        ramBar.style.width = `${ramPercent}%`;
        
        if (ramPercent >= this.config.thresholds.ramUsage.critical) {
          ramBar.style.background = `linear-gradient(90deg, ${this.config.theme.dangerColor}, #ff4500)`;
        } else if (ramPercent >= this.config.thresholds.ramUsage.warning) {
          ramBar.style.background = `linear-gradient(90deg, ${this.config.theme.warningColor}, #ffa500)`;
        }
      }

    } catch (error) {
      console.error('Error fetching system metrics:', error);
    }
  }

  updateSystemInfo() {
    // Update uptime
    const uptimeElement = document.getElementById('uptime');
    if (uptimeElement) {
      const hours = Math.floor(Math.random() * 72) + 24;
      uptimeElement.textContent = `${hours}h ${Math.floor(Math.random() * 60)}m`;
    }

    // Update total requests (mock)
    const requestsElement = document.getElementById('totalRequests');
    if (requestsElement) {
      const requests = Math.floor(Math.random() * 10000) + 50000;
      requestsElement.textContent = requests.toLocaleString();
    }

    // Update network I/O (mock)
    const networkElement = document.getElementById('networkIO');
    if (networkElement) {
      const download = (Math.random() * 100).toFixed(1);
      const upload = (Math.random() * 50).toFixed(1);
      networkElement.textContent = `↓ ${download} MB/s ↑ ${upload} MB/s`;
    }
  }

  updateServicesCount() {
    const activeElement = document.getElementById('activeServices');
    if (!activeElement) return;

    const total = this.config.services.length;
    let active = 0;

    this.servicesData.forEach(data => {
      if (data.status === 'online') active++;
    });

    activeElement.textContent = `${active}/${total}`;
    
    // Update system status badge
    const systemStatus = document.getElementById('systemStatus');
    if (systemStatus) {
      if (active === total) {
        systemStatus.innerHTML = '<span class="status-dot pulse"></span><span>ONLINE</span>';
        systemStatus.style.borderColor = this.config.theme.successColor;
      } else if (active > total / 2) {
        systemStatus.innerHTML = '<span class="status-dot pulse"></span><span>DEGRADED</span>';
        systemStatus.style.borderColor = this.config.theme.warningColor;
      } else {
        systemStatus.innerHTML = '<span class="status-dot pulse"></span><span>CRITICAL</span>';
        systemStatus.style.borderColor = this.config.theme.dangerColor;
      }
    }
  }

  addAlert(type, message) {
    const container = document.getElementById('alertsContainer');
    if (!container) return;

    // Check if alert already exists
    const existingAlerts = container.querySelectorAll('.alert-item');
    for (const alert of existingAlerts) {
      if (alert.textContent.includes(message)) return;
    }

    // Remove success message if adding warning/danger
    if (type !== 'success') {
      const successAlert = container.querySelector('.alert-item.success');
      if (successAlert) successAlert.remove();
    }

    const alert = document.createElement('div');
    alert.className = `alert-item ${type}`;
    
    const icon = type === 'success' ? '✓' : type === 'warning' ? '⚠' : '✗';
    alert.innerHTML = `
      <span class="alert-icon">${icon}</span>
      <span>${message}</span>
    `;

    container.appendChild(alert);

    // Auto-remove after 10 seconds
    setTimeout(() => {
      if (alert.parentNode) {
        alert.style.animation = 'fadeOut 0.3s ease';
        setTimeout(() => alert.remove(), 300);
      }
    }, 10000);
  }

  updateLastRefreshTime() {
    const element = document.getElementById('lastUpdate');
    if (element) {
      const now = new Date();
      element.textContent = now.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      });
    }
  }

  startAutoRefresh() {
    // Services refresh
    this.refreshTimers.services = setInterval(() => {
      this.fetchAllServices();
    }, this.config.refreshIntervals.services);

    // Metrics refresh
    this.refreshTimers.metrics = setInterval(() => {
      this.fetchMetrics();
    }, this.config.refreshIntervals.metrics);

    // System info refresh
    this.refreshTimers.systemInfo = setInterval(() => {
      this.updateSystemInfo();
      this.updateLastRefreshTime();
    }, this.config.refreshIntervals.systemInfo);

    console.log('✅ Auto-refresh enabled');
  }

  stopAutoRefresh() {
    Object.values(this.refreshTimers).forEach(timer => clearInterval(timer));
    this.refreshTimers = {};
    console.log('⏸️  Auto-refresh stopped');
  }
}

// Initialize dashboard when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new DashboardApp();
  });
} else {
  window.dashboard = new DashboardApp();
}

// Handle visibility change to pause/resume refresh
document.addEventListener('visibilitychange', () => {
  if (window.dashboard) {
    if (document.hidden) {
      console.log('📴 Dashboard hidden, pausing refresh...');
    } else {
      console.log('👀 Dashboard visible, refreshing...');
      window.dashboard.refreshAll();
    }
  }
});

#!/usr/bin/env python3
"""
Hardware Monitoring Agent - Main Flask Server

Monitors GPU, CPU, and memory metrics and provides REST API endpoints.
Stores metrics to disk and exposes Prometheus metrics.
"""

import os
import sys
import json
import time
import logging
from datetime import datetime
from typing import Dict, List, Optional, Any
from pathlib import Path

from flask import Flask, jsonify, Response
import psutil
import yaml
from prometheus_client import Counter, Gauge, Histogram, generate_latest, REGISTRY

# Import local modules
try:
    from rocm_control import get_gpu_stats, get_gpu_temperature, get_gpu_vram
    ROCM_AVAILABLE = True
except Exception as e:
    ROCM_AVAILABLE = False
    logging.warning(f"ROCm control not available: {e}")

from metrics import MetricsCollector
from optimizer import HardwareOptimizer

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('hardware_monitor_requests_total', 'Total requests', ['endpoint', 'method'])
REQUEST_LATENCY = Histogram('hardware_monitor_request_latency_seconds', 'Request latency', ['endpoint'])

# Hardware metrics
GPU_TEMPERATURE = Gauge('gpu_temperature_celsius', 'GPU temperature in Celsius', ['gpu_id'])
GPU_VRAM_USED = Gauge('gpu_vram_used_mb', 'GPU VRAM used in MB', ['gpu_id'])
GPU_VRAM_TOTAL = Gauge('gpu_vram_total_mb', 'GPU VRAM total in MB', ['gpu_id'])
GPU_UTILIZATION = Gauge('gpu_utilization_percent', 'GPU utilization percentage', ['gpu_id'])

CPU_USAGE = Gauge('cpu_usage_percent', 'CPU usage percentage', ['cpu'])
MEMORY_USED = Gauge('memory_used_mb', 'Memory used in MB')
MEMORY_TOTAL = Gauge('memory_total_mb', 'Memory total in MB')
MEMORY_PERCENT = Gauge('memory_percent', 'Memory usage percentage')

# Alert counters
ALERT_THRESHOLD_EXCEEDED = Counter('alert_threshold_exceeded_total', 'Alert thresholds exceeded', ['metric_type'])

# Global configuration
CONFIG = {}
METRICS_COLLECTOR = None
OPTIMIZER = None


def load_config() -> Dict[str, Any]:
    """Load configuration from config.yaml."""
    config_path = Path(__file__).parent / 'config.yaml'
    
    default_config = {
        'monitoring': {
            'interval': 30,
            'data_dir': '/app/data/metrics'
        },
        'alerts': {
            'gpu_temp_threshold': 80,
            'vram_usage_threshold': 90,
            'cpu_usage_threshold': 90,
            'memory_usage_threshold': 90
        },
        'metrics': {
            'retention_days': 7,
            'aggregation_intervals': [300, 3600, 86400]
        },
        'rocm': {
            'smi_path': '/opt/rocm/bin/rocm-smi',
            'enabled': True
        },
        'server': {
            'host': '0.0.0.0',
            'port': 5000
        }
    }
    
    if config_path.exists():
        try:
            with open(config_path, 'r') as f:
                file_config = yaml.safe_load(f)
                if file_config:
                    default_config.update(file_config)
            logger.info(f"Loaded configuration from {config_path}")
        except Exception as e:
            logger.error(f"Error loading config: {e}, using defaults")
    else:
        logger.warning(f"Config file not found at {config_path}, using defaults")
    
    # Override with environment variables
    if 'GPU_TEMP_THRESHOLD' in os.environ:
        default_config['alerts']['gpu_temp_threshold'] = int(os.environ['GPU_TEMP_THRESHOLD'])
    if 'VRAM_THRESHOLD' in os.environ:
        default_config['alerts']['vram_usage_threshold'] = int(os.environ['VRAM_THRESHOLD'])
    if 'CPU_THRESHOLD' in os.environ:
        default_config['alerts']['cpu_usage_threshold'] = int(os.environ['CPU_THRESHOLD'])
    if 'MEMORY_THRESHOLD' in os.environ:
        default_config['alerts']['memory_usage_threshold'] = int(os.environ['MEMORY_THRESHOLD'])
    
    return default_config


def get_cpu_metrics() -> Dict[str, Any]:
    """Get CPU metrics."""
    try:
        cpu_percent = psutil.cpu_percent(interval=1, percpu=True)
        cpu_avg = sum(cpu_percent) / len(cpu_percent)
        
        # Update Prometheus metrics
        for idx, usage in enumerate(cpu_percent):
            CPU_USAGE.labels(cpu=f'cpu{idx}').set(usage)
        
        metrics = {
            'timestamp': datetime.utcnow().isoformat(),
            'cpu_count': psutil.cpu_count(),
            'cpu_percent_per_core': cpu_percent,
            'cpu_percent_avg': cpu_avg,
            'cpu_freq': psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None
        }
        
        # Check alert threshold
        threshold = CONFIG['alerts']['cpu_usage_threshold']
        if cpu_avg > threshold:
            ALERT_THRESHOLD_EXCEEDED.labels(metric_type='cpu').inc()
            logger.warning(f"CPU usage {cpu_avg:.1f}% exceeds threshold {threshold}%")
        
        return metrics
    except Exception as e:
        logger.error(f"Error getting CPU metrics: {e}")
        return {'error': str(e)}


def get_memory_metrics() -> Dict[str, Any]:
    """Get memory metrics."""
    try:
        mem = psutil.virtual_memory()
        
        # Update Prometheus metrics
        MEMORY_USED.set(mem.used / (1024 * 1024))
        MEMORY_TOTAL.set(mem.total / (1024 * 1024))
        MEMORY_PERCENT.set(mem.percent)
        
        metrics = {
            'timestamp': datetime.utcnow().isoformat(),
            'total_mb': mem.total / (1024 * 1024),
            'available_mb': mem.available / (1024 * 1024),
            'used_mb': mem.used / (1024 * 1024),
            'percent': mem.percent,
            'swap': {
                'total_mb': psutil.swap_memory().total / (1024 * 1024),
                'used_mb': psutil.swap_memory().used / (1024 * 1024),
                'percent': psutil.swap_memory().percent
            }
        }
        
        # Check alert threshold
        threshold = CONFIG['alerts']['memory_usage_threshold']
        if mem.percent > threshold:
            ALERT_THRESHOLD_EXCEEDED.labels(metric_type='memory').inc()
            logger.warning(f"Memory usage {mem.percent:.1f}% exceeds threshold {threshold}%")
        
        return metrics
    except Exception as e:
        logger.error(f"Error getting memory metrics: {e}")
        return {'error': str(e)}


def get_gpu_metrics() -> Dict[str, Any]:
    """Get GPU metrics using ROCm if available, else psutil."""
    try:
        if ROCM_AVAILABLE and CONFIG['rocm']['enabled']:
            gpu_stats = get_gpu_stats()
            
            if gpu_stats and 'gpus' in gpu_stats:
                for gpu in gpu_stats['gpus']:
                    gpu_id = str(gpu.get('id', 0))
                    
                    # Update Prometheus metrics
                    if 'temperature' in gpu:
                        GPU_TEMPERATURE.labels(gpu_id=gpu_id).set(gpu['temperature'])
                    if 'vram_used_mb' in gpu:
                        GPU_VRAM_USED.labels(gpu_id=gpu_id).set(gpu['vram_used_mb'])
                    if 'vram_total_mb' in gpu:
                        GPU_VRAM_TOTAL.labels(gpu_id=gpu_id).set(gpu['vram_total_mb'])
                    if 'utilization' in gpu:
                        GPU_UTILIZATION.labels(gpu_id=gpu_id).set(gpu['utilization'])
                    
                    # Check temperature alert
                    temp_threshold = CONFIG['alerts']['gpu_temp_threshold']
                    if gpu.get('temperature', 0) > temp_threshold:
                        ALERT_THRESHOLD_EXCEEDED.labels(metric_type='gpu_temp').inc()
                        logger.warning(f"GPU {gpu_id} temperature {gpu['temperature']}°C exceeds threshold {temp_threshold}°C")
                    
                    # Check VRAM alert
                    vram_threshold = CONFIG['alerts']['vram_usage_threshold']
                    vram_percent = (gpu.get('vram_used_mb', 0) / gpu.get('vram_total_mb', 1)) * 100
                    if vram_percent > vram_threshold:
                        ALERT_THRESHOLD_EXCEEDED.labels(metric_type='gpu_vram').inc()
                        logger.warning(f"GPU {gpu_id} VRAM usage {vram_percent:.1f}% exceeds threshold {vram_threshold}%")
            
            return {
                'timestamp': datetime.utcnow().isoformat(),
                'source': 'rocm-smi',
                **gpu_stats
            }
        else:
            # Fallback to basic info
            return {
                'timestamp': datetime.utcnow().isoformat(),
                'source': 'psutil',
                'message': 'ROCm not available, limited GPU metrics',
                'gpus': []
            }
    except Exception as e:
        logger.error(f"Error getting GPU metrics: {e}")
        return {'error': str(e), 'source': 'error'}


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    REQUEST_COUNT.labels(endpoint='/health', method='GET').inc()
    
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0',
        'rocm_available': ROCM_AVAILABLE
    })


@app.route('/metrics', methods=['GET'])
def metrics_endpoint():
    """Prometheus metrics endpoint."""
    REQUEST_COUNT.labels(endpoint='/metrics', method='GET').inc()
    
    return Response(generate_latest(REGISTRY), mimetype='text/plain')


@app.route('/api/v1/metrics', methods=['GET'])
def all_metrics():
    """Get all metrics."""
    REQUEST_COUNT.labels(endpoint='/api/v1/metrics', method='GET').inc()
    
    with REQUEST_LATENCY.labels(endpoint='/api/v1/metrics').time():
        return jsonify({
            'timestamp': datetime.utcnow().isoformat(),
            'gpu': get_gpu_metrics(),
            'cpu': get_cpu_metrics(),
            'memory': get_memory_metrics()
        })


@app.route('/api/v1/gpu', methods=['GET'])
def gpu_metrics():
    """Get GPU metrics."""
    REQUEST_COUNT.labels(endpoint='/api/v1/gpu', method='GET').inc()
    
    with REQUEST_LATENCY.labels(endpoint='/api/v1/gpu').time():
        return jsonify(get_gpu_metrics())


@app.route('/api/v1/cpu', methods=['GET'])
def cpu_metrics():
    """Get CPU metrics."""
    REQUEST_COUNT.labels(endpoint='/api/v1/cpu', method='GET').inc()
    
    with REQUEST_LATENCY.labels(endpoint='/api/v1/cpu').time():
        return jsonify(get_cpu_metrics())


@app.route('/api/v1/memory', methods=['GET'])
def memory_metrics():
    """Get memory metrics."""
    REQUEST_COUNT.labels(endpoint='/api/v1/memory', method='GET').inc()
    
    with REQUEST_LATENCY.labels(endpoint='/api/v1/memory').time():
        return jsonify(get_memory_metrics())


@app.route('/api/v1/optimizer/recommendations', methods=['GET'])
def optimizer_recommendations():
    """Get hardware optimization recommendations."""
    REQUEST_COUNT.labels(endpoint='/api/v1/optimizer/recommendations', method='GET').inc()
    
    try:
        if OPTIMIZER:
            recommendations = OPTIMIZER.get_recommendations()
            return jsonify(recommendations)
        else:
            return jsonify({'error': 'Optimizer not initialized'}), 500
    except Exception as e:
        logger.error(f"Error getting recommendations: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/v1/metrics/history', methods=['GET'])
def metrics_history():
    """Get historical metrics."""
    REQUEST_COUNT.labels(endpoint='/api/v1/metrics/history', method='GET').inc()
    
    try:
        from flask import request
        hours = int(request.args.get('hours', 1))
        
        if METRICS_COLLECTOR:
            history = METRICS_COLLECTOR.get_history(hours=hours)
            return jsonify(history)
        else:
            return jsonify({'error': 'Metrics collector not initialized'}), 500
    except Exception as e:
        logger.error(f"Error getting metrics history: {e}")
        return jsonify({'error': str(e)}), 500


def initialize_services():
    """Initialize metrics collector and optimizer."""
    global METRICS_COLLECTOR, OPTIMIZER
    
    try:
        # Initialize metrics collector
        data_dir = CONFIG['monitoring']['data_dir']
        interval = CONFIG['monitoring']['interval']
        retention_days = CONFIG['metrics']['retention_days']
        
        METRICS_COLLECTOR = MetricsCollector(
            data_dir=data_dir,
            interval=interval,
            retention_days=retention_days
        )
        METRICS_COLLECTOR.start()
        logger.info("Metrics collector started")
        
        # Initialize optimizer
        OPTIMIZER = HardwareOptimizer(metrics_collector=METRICS_COLLECTOR)
        logger.info("Hardware optimizer initialized")
        
    except Exception as e:
        logger.error(f"Error initializing services: {e}")
        raise


def main():
    """Main entry point."""
    global CONFIG
    
    try:
        # Load configuration
        CONFIG = load_config()
        logger.info("Configuration loaded")
        
        # Initialize services
        initialize_services()
        
        # Start Flask app
        host = CONFIG['server']['host']
        port = CONFIG['server']['port']
        
        logger.info(f"Starting hardware monitoring agent on {host}:{port}")
        app.run(host=host, port=port, debug=False, threaded=True)
        
    except KeyboardInterrupt:
        logger.info("Shutting down gracefully...")
        if METRICS_COLLECTOR:
            METRICS_COLLECTOR.stop()
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()

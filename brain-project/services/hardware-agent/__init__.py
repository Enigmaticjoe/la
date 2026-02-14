"""
Hardware Monitoring Agent

A production-ready hardware monitoring service for GPU, CPU, and memory metrics.
"""

__version__ = '1.0.0'
__author__ = 'Brain Project Team'

from .monitor import app
from .rocm_control import get_gpu_stats, get_gpu_temperature, get_gpu_vram
from .optimizer import HardwareOptimizer
from .metrics import MetricsCollector

__all__ = [
    'app',
    'get_gpu_stats',
    'get_gpu_temperature',
    'get_gpu_vram',
    'HardwareOptimizer',
    'MetricsCollector',
]

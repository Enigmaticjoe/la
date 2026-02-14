#!/usr/bin/env python3
"""
Metrics Collection and Storage

Collects system metrics at regular intervals and stores them to disk.
Provides aggregation and query functions for historical data.
"""

import os
import json
import logging
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any, Optional
from collections import defaultdict
import gzip

logger = logging.getLogger(__name__)


class MetricsCollector:
    """
    Background metrics collector that stores data to disk.
    """
    
    def __init__(self, data_dir: str = '/app/data/metrics', interval: int = 30, retention_days: int = 7):
        """
        Initialize metrics collector.
        
        Args:
            data_dir: Directory to store metrics files
            interval: Collection interval in seconds
            retention_days: Number of days to retain metrics
        """
        self.data_dir = Path(data_dir)
        self.interval = interval
        self.retention_days = retention_days
        
        self.running = False
        self.thread = None
        
        # Create data directory
        self.data_dir.mkdir(parents=True, exist_ok=True)
        logger.info(f"Metrics will be stored in {self.data_dir}")
    
    def start(self):
        """Start the metrics collection thread."""
        if self.running:
            logger.warning("Metrics collector already running")
            return
        
        self.running = True
        self.thread = threading.Thread(target=self._collection_loop, daemon=True)
        self.thread.start()
        logger.info(f"Metrics collector started (interval: {self.interval}s)")
    
    def stop(self):
        """Stop the metrics collection thread."""
        self.running = False
        if self.thread:
            self.thread.join(timeout=5)
        logger.info("Metrics collector stopped")
    
    def _collection_loop(self):
        """Main collection loop."""
        while self.running:
            try:
                # Collect metrics
                metrics = self._collect_metrics()
                
                # Store to disk
                self._store_metrics(metrics)
                
                # Cleanup old files
                self._cleanup_old_metrics()
                
            except Exception as e:
                logger.error(f"Error in metrics collection: {e}")
            
            # Sleep for interval
            time.sleep(self.interval)
    
    def _collect_metrics(self) -> Dict[str, Any]:
        """
        Collect current metrics from all sources.
        
        Returns:
            Dictionary with all current metrics
        """
        import psutil
        
        metrics = {
            'timestamp': datetime.utcnow().isoformat(),
            'cpu': {},
            'memory': {},
            'gpu': {}
        }
        
        try:
            # CPU metrics
            cpu_percent = psutil.cpu_percent(interval=1, percpu=True)
            metrics['cpu'] = {
                'cpu_count': psutil.cpu_count(),
                'cpu_percent_per_core': cpu_percent,
                'cpu_percent_avg': sum(cpu_percent) / len(cpu_percent) if cpu_percent else 0,
                'cpu_freq': psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None
            }
            
            # Memory metrics
            mem = psutil.virtual_memory()
            swap = psutil.swap_memory()
            metrics['memory'] = {
                'total_mb': mem.total / (1024 * 1024),
                'available_mb': mem.available / (1024 * 1024),
                'used_mb': mem.used / (1024 * 1024),
                'percent': mem.percent,
                'swap_total_mb': swap.total / (1024 * 1024),
                'swap_used_mb': swap.used / (1024 * 1024),
                'swap_percent': swap.percent
            }
            
            # GPU metrics (if available)
            try:
                from rocm_control import get_gpu_stats
                gpu_stats = get_gpu_stats()
                metrics['gpu'] = gpu_stats
            except Exception as e:
                logger.debug(f"GPU metrics not available: {e}")
                metrics['gpu'] = {'available': False, 'gpus': []}
        
        except Exception as e:
            logger.error(f"Error collecting metrics: {e}")
        
        return metrics
    
    def _store_metrics(self, metrics: Dict[str, Any]):
        """
        Store metrics to disk as JSON file.
        
        Args:
            metrics: Metrics dictionary to store
        """
        try:
            # Create filename with timestamp
            timestamp = datetime.utcnow()
            date_dir = self.data_dir / timestamp.strftime('%Y-%m-%d')
            date_dir.mkdir(exist_ok=True)
            
            filename = f"metrics_{timestamp.strftime('%Y%m%d_%H%M%S')}.json"
            filepath = date_dir / filename
            
            # Write JSON file
            with open(filepath, 'w') as f:
                json.dump(metrics, f, indent=2)
            
            logger.debug(f"Stored metrics to {filepath}")
            
        except Exception as e:
            logger.error(f"Error storing metrics: {e}")
    
    def _cleanup_old_metrics(self):
        """Remove metrics files older than retention period."""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=self.retention_days)
            
            for date_dir in self.data_dir.iterdir():
                if not date_dir.is_dir():
                    continue
                
                try:
                    # Parse directory name as date
                    dir_date = datetime.strptime(date_dir.name, '%Y-%m-%d')
                    
                    if dir_date < cutoff_date:
                        # Remove old directory
                        for file in date_dir.iterdir():
                            file.unlink()
                        date_dir.rmdir()
                        logger.info(f"Removed old metrics directory: {date_dir}")
                
                except ValueError:
                    # Not a date directory, skip
                    continue
        
        except Exception as e:
            logger.error(f"Error cleaning up old metrics: {e}")
    
    def get_recent_metrics(self, minutes: int = 60) -> List[Dict[str, Any]]:
        """
        Get metrics from the last N minutes.
        
        Args:
            minutes: Number of minutes to look back
            
        Returns:
            List of metrics dictionaries
        """
        try:
            cutoff_time = datetime.utcnow() - timedelta(minutes=minutes)
            metrics_list = []
            
            # Check recent date directories
            for days_back in range(2):  # Check today and yesterday
                check_date = datetime.utcnow() - timedelta(days=days_back)
                date_dir = self.data_dir / check_date.strftime('%Y-%m-%d')
                
                if not date_dir.exists():
                    continue
                
                # Read all metrics files in directory
                for filepath in sorted(date_dir.glob('metrics_*.json')):
                    try:
                        with open(filepath, 'r') as f:
                            metrics = json.load(f)
                        
                        # Check timestamp
                        timestamp = datetime.fromisoformat(metrics['timestamp'])
                        if timestamp >= cutoff_time:
                            metrics_list.append(metrics)
                    
                    except Exception as e:
                        logger.debug(f"Error reading metrics file {filepath}: {e}")
            
            return sorted(metrics_list, key=lambda m: m['timestamp'])
        
        except Exception as e:
            logger.error(f"Error getting recent metrics: {e}")
            return []
    
    def get_history(self, hours: int = 1) -> Dict[str, Any]:
        """
        Get historical metrics with summary statistics.
        
        Args:
            hours: Number of hours to look back
            
        Returns:
            Dictionary with metrics history and aggregations
        """
        try:
            metrics_list = self.get_recent_metrics(minutes=hours * 60)
            
            if not metrics_list:
                return {
                    'period_hours': hours,
                    'data_points': 0,
                    'metrics': []
                }
            
            # Calculate aggregations
            aggregations = self._calculate_aggregations(metrics_list)
            
            return {
                'period_hours': hours,
                'data_points': len(metrics_list),
                'start_time': metrics_list[0]['timestamp'],
                'end_time': metrics_list[-1]['timestamp'],
                'metrics': metrics_list,
                'aggregations': aggregations
            }
        
        except Exception as e:
            logger.error(f"Error getting metrics history: {e}")
            return {'error': str(e)}
    
    def _calculate_aggregations(self, metrics_list: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Calculate min, max, avg for metrics.
        
        Args:
            metrics_list: List of metrics dictionaries
            
        Returns:
            Dictionary with aggregated statistics
        """
        aggregations = {
            'cpu': {},
            'memory': {},
            'gpu': {}
        }
        
        try:
            # CPU aggregations
            cpu_avgs = [m['cpu'].get('cpu_percent_avg', 0) for m in metrics_list if 'cpu' in m]
            if cpu_avgs:
                aggregations['cpu'] = {
                    'avg': sum(cpu_avgs) / len(cpu_avgs),
                    'min': min(cpu_avgs),
                    'max': max(cpu_avgs)
                }
            
            # Memory aggregations
            mem_percents = [m['memory'].get('percent', 0) for m in metrics_list if 'memory' in m]
            if mem_percents:
                aggregations['memory'] = {
                    'percent_avg': sum(mem_percents) / len(mem_percents),
                    'percent_min': min(mem_percents),
                    'percent_max': max(mem_percents)
                }
            
            # GPU aggregations
            gpu_temps = []
            gpu_vram = []
            
            for m in metrics_list:
                if 'gpu' in m and 'gpus' in m['gpu']:
                    for gpu in m['gpu']['gpus']:
                        if 'temperature' in gpu:
                            gpu_temps.append(gpu['temperature'])
                        if 'vram_used_mb' in gpu and 'vram_total_mb' in gpu and gpu['vram_total_mb'] > 0:
                            gpu_vram.append((gpu['vram_used_mb'] / gpu['vram_total_mb']) * 100)
            
            if gpu_temps:
                aggregations['gpu']['temperature'] = {
                    'avg': sum(gpu_temps) / len(gpu_temps),
                    'min': min(gpu_temps),
                    'max': max(gpu_temps)
                }
            
            if gpu_vram:
                aggregations['gpu']['vram_percent'] = {
                    'avg': sum(gpu_vram) / len(gpu_vram),
                    'min': min(gpu_vram),
                    'max': max(gpu_vram)
                }
        
        except Exception as e:
            logger.error(f"Error calculating aggregations: {e}")
        
        return aggregations
    
    def export_metrics(self, filepath: str, hours: int = 24, compress: bool = True):
        """
        Export metrics to a file.
        
        Args:
            filepath: Output file path
            hours: Number of hours to export
            compress: Whether to gzip compress the output
        """
        try:
            history = self.get_history(hours=hours)
            
            if compress:
                with gzip.open(filepath, 'wt', encoding='utf-8') as f:
                    json.dump(history, f, indent=2)
            else:
                with open(filepath, 'w') as f:
                    json.dump(history, f, indent=2)
            
            logger.info(f"Exported {history['data_points']} metrics to {filepath}")
            
        except Exception as e:
            logger.error(f"Error exporting metrics: {e}")


if __name__ == '__main__':
    # Test metrics collector
    logging.basicConfig(level=logging.INFO)
    
    collector = MetricsCollector(data_dir='./test_metrics', interval=5, retention_days=1)
    
    print("Starting metrics collector...")
    collector.start()
    
    # Run for 30 seconds
    time.sleep(30)
    
    print("\nRecent metrics:")
    recent = collector.get_recent_metrics(minutes=1)
    print(f"Collected {len(recent)} data points")
    
    print("\nHistory:")
    history = collector.get_history(hours=1)
    print(json.dumps(history.get('aggregations', {}), indent=2))
    
    collector.stop()
    print("\nStopped collector")

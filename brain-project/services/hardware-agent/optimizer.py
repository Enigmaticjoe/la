#!/usr/bin/env python3
"""
Hardware Optimization Logic

Analyzes hardware metrics and provides optimization recommendations.
"""

import logging
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from collections import defaultdict

logger = logging.getLogger(__name__)


class HardwareOptimizer:
    """
    Hardware optimization analyzer and recommendation engine.
    """
    
    def __init__(self, metrics_collector=None):
        """
        Initialize optimizer.
        
        Args:
            metrics_collector: MetricsCollector instance for historical data
        """
        self.metrics_collector = metrics_collector
        self.recommendations_cache = {}
        self.last_analysis = None
        
        # Thresholds for recommendations
        self.thresholds = {
            'gpu_temp_warning': 75,
            'gpu_temp_critical': 85,
            'gpu_temp_throttle': 90,
            'vram_low': 20,
            'vram_high': 85,
            'vram_critical': 95,
            'cpu_high': 80,
            'memory_high': 85,
            'utilization_low': 30,
            'utilization_optimal': 70
        }
    
    def analyze_gpu_utilization(self, gpu_data: List[Dict[str, Any]]) -> List[Dict[str, str]]:
        """
        Analyze GPU utilization patterns.
        
        Args:
            gpu_data: List of GPU metrics over time
            
        Returns:
            List of recommendations
        """
        recommendations = []
        
        if not gpu_data:
            return recommendations
        
        try:
            # Calculate average utilization
            utilizations = [g.get('utilization', 0) for g in gpu_data if 'utilization' in g]
            
            if utilizations:
                avg_util = sum(utilizations) / len(utilizations)
                max_util = max(utilizations)
                min_util = min(utilizations)
                
                # Low utilization
                if avg_util < self.thresholds['utilization_low']:
                    recommendations.append({
                        'type': 'gpu_utilization',
                        'severity': 'info',
                        'title': 'Low GPU Utilization',
                        'message': f'Average GPU utilization is {avg_util:.1f}%. Consider reducing allocated resources or consolidating workloads.',
                        'metric': avg_util
                    })
                
                # Highly variable utilization
                elif max_util - min_util > 50:
                    recommendations.append({
                        'type': 'gpu_utilization',
                        'severity': 'info',
                        'title': 'Variable GPU Utilization',
                        'message': f'GPU utilization varies significantly ({min_util:.1f}% - {max_util:.1f}%). Consider workload scheduling optimization.',
                        'metric': max_util - min_util
                    })
                
                # Optimal utilization
                elif self.thresholds['utilization_low'] <= avg_util <= self.thresholds['utilization_optimal']:
                    recommendations.append({
                        'type': 'gpu_utilization',
                        'severity': 'success',
                        'title': 'Optimal GPU Utilization',
                        'message': f'GPU utilization is at optimal level ({avg_util:.1f}%).',
                        'metric': avg_util
                    })
        
        except Exception as e:
            logger.error(f"Error analyzing GPU utilization: {e}")
        
        return recommendations
    
    def analyze_thermal_performance(self, gpu_data: List[Dict[str, Any]]) -> List[Dict[str, str]]:
        """
        Detect thermal throttling and temperature issues.
        
        Args:
            gpu_data: List of GPU metrics over time
            
        Returns:
            List of recommendations
        """
        recommendations = []
        
        if not gpu_data:
            return recommendations
        
        try:
            temperatures = [g.get('temperature', 0) for g in gpu_data if 'temperature' in g]
            
            if temperatures:
                avg_temp = sum(temperatures) / len(temperatures)
                max_temp = max(temperatures)
                
                # Critical temperature
                if max_temp >= self.thresholds['gpu_temp_critical']:
                    recommendations.append({
                        'type': 'thermal',
                        'severity': 'critical',
                        'title': 'Critical GPU Temperature',
                        'message': f'GPU temperature reached {max_temp}°C. Immediate action required: check cooling, reduce workload, or lower power limits.',
                        'metric': max_temp
                    })
                
                # Thermal throttling risk
                elif max_temp >= self.thresholds['gpu_temp_warning']:
                    recommendations.append({
                        'type': 'thermal',
                        'severity': 'warning',
                        'title': 'High GPU Temperature',
                        'message': f'GPU temperature averaging {avg_temp:.1f}°C (max {max_temp}°C). Consider improving cooling or reducing power limits.',
                        'metric': max_temp
                    })
                
                # Check for thermal throttling pattern
                throttle_events = sum(1 for t in temperatures if t >= self.thresholds['gpu_temp_throttle'])
                if throttle_events > len(temperatures) * 0.1:  # More than 10% of readings
                    recommendations.append({
                        'type': 'thermal',
                        'severity': 'critical',
                        'title': 'Thermal Throttling Detected',
                        'message': f'GPU is throttling due to temperature ({throttle_events} events). Performance is degraded. Improve cooling immediately.',
                        'metric': throttle_events
                    })
        
        except Exception as e:
            logger.error(f"Error analyzing thermal performance: {e}")
        
        return recommendations
    
    def analyze_vram_allocation(self, gpu_data: List[Dict[str, Any]]) -> List[Dict[str, str]]:
        """
        Suggest optimal VRAM allocation.
        
        Args:
            gpu_data: List of GPU metrics over time
            
        Returns:
            List of recommendations
        """
        recommendations = []
        
        if not gpu_data:
            return recommendations
        
        try:
            vram_usage = []
            for g in gpu_data:
                if 'vram_used_mb' in g and 'vram_total_mb' in g and g['vram_total_mb'] > 0:
                    percent = (g['vram_used_mb'] / g['vram_total_mb']) * 100
                    vram_usage.append({
                        'percent': percent,
                        'used_mb': g['vram_used_mb'],
                        'total_mb': g['vram_total_mb']
                    })
            
            if vram_usage:
                avg_percent = sum(v['percent'] for v in vram_usage) / len(vram_usage)
                max_percent = max(v['percent'] for v in vram_usage)
                avg_used = sum(v['used_mb'] for v in vram_usage) / len(vram_usage)
                total = vram_usage[0]['total_mb']
                
                # VRAM exhaustion risk
                if max_percent >= self.thresholds['vram_critical']:
                    recommendations.append({
                        'type': 'vram',
                        'severity': 'critical',
                        'title': 'VRAM Exhaustion Risk',
                        'message': f'VRAM usage at {max_percent:.1f}% ({avg_used:.0f}MB / {total}MB). Reduce batch sizes, model layers, or context length.',
                        'metric': max_percent
                    })
                
                # High VRAM usage
                elif avg_percent >= self.thresholds['vram_high']:
                    recommendations.append({
                        'type': 'vram',
                        'severity': 'warning',
                        'title': 'High VRAM Usage',
                        'message': f'VRAM usage averaging {avg_percent:.1f}%. Consider optimization to prevent OOM errors.',
                        'metric': avg_percent
                    })
                
                # Low VRAM usage
                elif avg_percent < self.thresholds['vram_low']:
                    headroom = total - avg_used
                    recommendations.append({
                        'type': 'vram',
                        'severity': 'info',
                        'title': 'VRAM Underutilized',
                        'message': f'VRAM usage at {avg_percent:.1f}%. You have {headroom:.0f}MB available - consider larger batch sizes or models.',
                        'metric': avg_percent
                    })
        
        except Exception as e:
            logger.error(f"Error analyzing VRAM allocation: {e}")
        
        return recommendations
    
    def analyze_cpu_memory(self, cpu_data: List[Dict[str, Any]], mem_data: List[Dict[str, Any]]) -> List[Dict[str, str]]:
        """
        Analyze CPU and memory usage patterns.
        
        Args:
            cpu_data: List of CPU metrics over time
            mem_data: List of memory metrics over time
            
        Returns:
            List of recommendations
        """
        recommendations = []
        
        try:
            # Analyze CPU
            if cpu_data:
                cpu_usages = [c.get('cpu_percent_avg', 0) for c in cpu_data if 'cpu_percent_avg' in c]
                
                if cpu_usages:
                    avg_cpu = sum(cpu_usages) / len(cpu_usages)
                    
                    if avg_cpu >= self.thresholds['cpu_high']:
                        recommendations.append({
                            'type': 'cpu',
                            'severity': 'warning',
                            'title': 'High CPU Usage',
                            'message': f'CPU usage averaging {avg_cpu:.1f}%. Consider optimizing CPU-intensive preprocessing or data loading.',
                            'metric': avg_cpu
                        })
            
            # Analyze Memory
            if mem_data:
                mem_percents = [m.get('percent', 0) for m in mem_data if 'percent' in m]
                
                if mem_percents:
                    avg_mem = sum(mem_percents) / len(mem_percents)
                    max_mem = max(mem_percents)
                    
                    if max_mem >= self.thresholds['memory_high']:
                        recommendations.append({
                            'type': 'memory',
                            'severity': 'warning',
                            'title': 'High Memory Usage',
                            'message': f'Memory usage at {max_mem:.1f}% (avg {avg_mem:.1f}%). Monitor for memory leaks or consider increasing RAM.',
                            'metric': max_mem
                        })
        
        except Exception as e:
            logger.error(f"Error analyzing CPU/memory: {e}")
        
        return recommendations
    
    def get_performance_score(self) -> Dict[str, Any]:
        """
        Calculate overall performance score.
        
        Returns:
            Performance score and rating
        """
        try:
            if not self.metrics_collector:
                return {'score': 0, 'rating': 'unknown', 'message': 'No metrics available'}
            
            # Get recent metrics
            recent = self.metrics_collector.get_recent_metrics(minutes=10)
            
            if not recent:
                return {'score': 0, 'rating': 'unknown', 'message': 'Insufficient data'}
            
            score = 100
            factors = []
            
            # GPU temperature factor
            temps = [m['gpu'].get('temperature', 0) for m in recent if 'gpu' in m and 'temperature' in m.get('gpu', {})]
            if temps:
                avg_temp = sum(temps) / len(temps)
                if avg_temp > self.thresholds['gpu_temp_critical']:
                    score -= 30
                    factors.append(f"Critical temperature: -{30}")
                elif avg_temp > self.thresholds['gpu_temp_warning']:
                    score -= 15
                    factors.append(f"High temperature: -{15}")
            
            # VRAM factor
            vram_usage = []
            for m in recent:
                if 'gpu' in m and 'gpus' in m['gpu']:
                    for gpu in m['gpu']['gpus']:
                        if 'vram_used_mb' in gpu and 'vram_total_mb' in gpu and gpu['vram_total_mb'] > 0:
                            vram_usage.append((gpu['vram_used_mb'] / gpu['vram_total_mb']) * 100)
            
            if vram_usage:
                avg_vram = sum(vram_usage) / len(vram_usage)
                if avg_vram > self.thresholds['vram_critical']:
                    score -= 20
                    factors.append(f"VRAM critical: -{20}")
                elif avg_vram > self.thresholds['vram_high']:
                    score -= 10
                    factors.append(f"VRAM high: -{10}")
            
            # Determine rating
            if score >= 90:
                rating = 'excellent'
            elif score >= 75:
                rating = 'good'
            elif score >= 60:
                rating = 'fair'
            elif score >= 40:
                rating = 'poor'
            else:
                rating = 'critical'
            
            return {
                'score': max(0, score),
                'rating': rating,
                'factors': factors,
                'timestamp': datetime.utcnow().isoformat()
            }
        
        except Exception as e:
            logger.error(f"Error calculating performance score: {e}")
            return {'score': 0, 'rating': 'error', 'message': str(e)}
    
    def get_recommendations(self) -> Dict[str, Any]:
        """
        Get all optimization recommendations.
        
        Returns:
            Dictionary with recommendations and analysis
        """
        try:
            recommendations = []
            
            if not self.metrics_collector:
                return {
                    'recommendations': [],
                    'performance_score': self.get_performance_score(),
                    'timestamp': datetime.utcnow().isoformat(),
                    'message': 'Metrics collector not available'
                }
            
            # Get recent metrics for analysis
            recent_metrics = self.metrics_collector.get_recent_metrics(minutes=30)
            
            if not recent_metrics:
                return {
                    'recommendations': [],
                    'performance_score': self.get_performance_score(),
                    'timestamp': datetime.utcnow().isoformat(),
                    'message': 'Insufficient metrics data'
                }
            
            # Extract GPU, CPU, and memory data
            gpu_data = []
            cpu_data = []
            mem_data = []
            
            for metric in recent_metrics:
                if 'gpu' in metric and 'gpus' in metric['gpu']:
                    gpu_data.extend(metric['gpu']['gpus'])
                if 'cpu' in metric:
                    cpu_data.append(metric['cpu'])
                if 'memory' in metric:
                    mem_data.append(metric['memory'])
            
            # Run analyses
            recommendations.extend(self.analyze_gpu_utilization(gpu_data))
            recommendations.extend(self.analyze_thermal_performance(gpu_data))
            recommendations.extend(self.analyze_vram_allocation(gpu_data))
            recommendations.extend(self.analyze_cpu_memory(cpu_data, mem_data))
            
            # Sort by severity
            severity_order = {'critical': 0, 'warning': 1, 'info': 2, 'success': 3}
            recommendations.sort(key=lambda r: severity_order.get(r.get('severity', 'info'), 99))
            
            return {
                'recommendations': recommendations,
                'recommendation_count': len(recommendations),
                'critical_count': sum(1 for r in recommendations if r.get('severity') == 'critical'),
                'warning_count': sum(1 for r in recommendations if r.get('severity') == 'warning'),
                'performance_score': self.get_performance_score(),
                'analysis_period_minutes': 30,
                'timestamp': datetime.utcnow().isoformat()
            }
        
        except Exception as e:
            logger.error(f"Error getting recommendations: {e}")
            return {
                'recommendations': [],
                'error': str(e),
                'timestamp': datetime.utcnow().isoformat()
            }


if __name__ == '__main__':
    # Test optimizer
    logging.basicConfig(level=logging.INFO)
    
    optimizer = HardwareOptimizer()
    print("Performance Score:", optimizer.get_performance_score())
    print("\nRecommendations:", optimizer.get_recommendations())

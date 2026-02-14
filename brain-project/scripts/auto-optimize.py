#!/usr/bin/env python3
"""
Auto-Optimization System - Monitors and tunes system resources

Monitors:
- GPU VRAM usage patterns
- vLLM performance metrics
- Qdrant database performance
- Context window usage
- Token throughput

Actions:
- Suggests optimal vLLM gpu-memory-utilization setting
- Detects slow RAG retrieval and optimizes Qdrant
- Recommends max-model-len adjustments
- Provides optimization recommendations with reasoning
"""

import os
import sys
import json
import time
import logging
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import statistics

import requests
import yaml

# Configuration
VLLM_URL = os.getenv("VLLM_URL", "http://vllm:8000")
QDRANT_URL = os.getenv("QDRANT_URL", "http://qdrant:6333")
NVIDIA_SMI_PATH = os.getenv("NVIDIA_SMI_PATH", "/usr/bin/nvidia-smi")
OPTIMIZATION_LOG = os.getenv("OPTIMIZATION_LOG", "/data/evolution/auto-optimize.log")
CHECK_INTERVAL = int(os.getenv("OPTIMIZE_CHECK_INTERVAL", "60"))  # 1 minute

# Thresholds
VRAM_WARNING_THRESHOLD = 0.90  # 90% usage
VRAM_OPTIMAL_RANGE = (0.75, 0.85)  # 75-85% is optimal
SLOW_RESPONSE_THRESHOLD = 2.0  # seconds
TOKEN_THROUGHPUT_MIN = 50  # tokens/second

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(OPTIMIZATION_LOG),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("auto-optimize")


class GPUMonitor:
    """Monitors GPU VRAM usage and performance"""
    
    def __init__(self):
        self.nvidia_smi = NVIDIA_SMI_PATH
        self.history = []
        self.max_history = 100
    
    def get_gpu_stats(self) -> Optional[Dict]:
        """Get current GPU statistics"""
        try:
            # Query nvidia-smi for GPU stats
            result = subprocess.run(
                [
                    self.nvidia_smi,
                    "--query-gpu=memory.total,memory.used,memory.free,utilization.gpu,temperature.gpu",
                    "--format=csv,noheader,nounits"
                ],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode != 0:
                logger.warning("nvidia-smi failed")
                return None
            
            # Parse output
            values = result.stdout.strip().split(', ')
            
            stats = {
                "memory_total_mb": float(values[0]),
                "memory_used_mb": float(values[1]),
                "memory_free_mb": float(values[2]),
                "gpu_utilization_pct": float(values[3]),
                "temperature_c": float(values[4]),
                "timestamp": datetime.now()
            }
            
            stats["memory_usage_pct"] = (stats["memory_used_mb"] / stats["memory_total_mb"]) * 100
            
            # Add to history
            self.history.append(stats)
            if len(self.history) > self.max_history:
                self.history.pop(0)
            
            return stats
            
        except Exception as e:
            logger.error(f"Error getting GPU stats: {e}")
            return None
    
    def get_vram_recommendations(self) -> List[str]:
        """Get recommendations based on VRAM usage patterns"""
        if len(self.history) < 10:
            return ["Collecting VRAM data... need more samples"]
        
        recommendations = []
        
        # Calculate average usage
        avg_usage = statistics.mean([s["memory_usage_pct"] for s in self.history])
        max_usage = max([s["memory_usage_pct"] for s in self.history])
        
        logger.info(f"VRAM Usage - Avg: {avg_usage:.1f}%, Max: {max_usage:.1f}%")
        
        # Check if usage is too high
        if max_usage > VRAM_WARNING_THRESHOLD * 100:
            recommendations.append(
                f"⚠️  VRAM usage critical: {max_usage:.1f}%. "
                "Consider reducing gpu-memory-utilization or using a smaller model. "
                f"Current peak usage suggests setting gpu-memory-utilization to {max(0.5, max_usage/100 - 0.1):.2f}"
            )
        
        # Check if usage is too low (wasting resources)
        elif avg_usage < VRAM_OPTIMAL_RANGE[0] * 100:
            optimal_utilization = min(0.95, avg_usage/100 + 0.15)
            recommendations.append(
                f"💡 VRAM underutilized: {avg_usage:.1f}%. "
                f"Can increase gpu-memory-utilization to {optimal_utilization:.2f} for better performance. "
                "This allows larger batch sizes and faster inference."
            )
        
        # Check if in optimal range
        elif VRAM_OPTIMAL_RANGE[0] * 100 <= avg_usage <= VRAM_OPTIMAL_RANGE[1] * 100:
            recommendations.append(
                f"✅ VRAM usage optimal: {avg_usage:.1f}% (target: 75-85%)"
            )
        
        # Temperature warnings
        avg_temp = statistics.mean([s["temperature_c"] for s in self.history])
        if avg_temp > 80:
            recommendations.append(
                f"🔥 GPU temperature high: {avg_temp:.1f}°C. Check cooling/airflow."
            )
        
        return recommendations


class VLLMMonitor:
    """Monitors vLLM performance"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.metrics_history = []
        self.max_history = 50
    
    def get_metrics(self) -> Optional[Dict]:
        """Get vLLM metrics"""
        try:
            response = requests.get(
                f"{self.base_url}/metrics",
                timeout=5
            )
            
            if response.status_code == 200:
                # Parse Prometheus metrics
                metrics = self._parse_prometheus(response.text)
                metrics["timestamp"] = datetime.now()
                
                self.metrics_history.append(metrics)
                if len(self.metrics_history) > self.max_history:
                    self.metrics_history.pop(0)
                
                return metrics
            else:
                logger.warning(f"Failed to fetch vLLM metrics: {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"Error fetching vLLM metrics: {e}")
            return None
    
    def _parse_prometheus(self, metrics_text: str) -> Dict:
        """Parse Prometheus metrics format"""
        metrics = {}
        
        for line in metrics_text.split('\n'):
            if line.startswith('#') or not line.strip():
                continue
            
            try:
                parts = line.split()
                if len(parts) >= 2:
                    key = parts[0]
                    value = float(parts[1])
                    metrics[key] = value
            except:
                continue
        
        return metrics
    
    def get_performance_recommendations(self) -> List[str]:
        """Get recommendations based on vLLM performance"""
        if len(self.metrics_history) < 5:
            return ["Collecting vLLM metrics... need more samples"]
        
        recommendations = []
        
        # Calculate token throughput if available
        if "vllm:num_generation_tokens_total" in self.metrics_history[-1]:
            recent_tokens = []
            for i in range(1, min(10, len(self.metrics_history))):
                curr = self.metrics_history[-i]
                prev = self.metrics_history[-i-1] if i < len(self.metrics_history) else None
                
                if prev and "vllm:num_generation_tokens_total" in curr and "vllm:num_generation_tokens_total" in prev:
                    time_diff = (curr["timestamp"] - prev["timestamp"]).total_seconds()
                    token_diff = curr["vllm:num_generation_tokens_total"] - prev["vllm:num_generation_tokens_total"]
                    
                    if time_diff > 0:
                        throughput = token_diff / time_diff
                        recent_tokens.append(throughput)
            
            if recent_tokens:
                avg_throughput = statistics.mean(recent_tokens)
                logger.info(f"Token throughput: {avg_throughput:.1f} tokens/sec")
                
                if avg_throughput < TOKEN_THROUGHPUT_MIN:
                    recommendations.append(
                        f"⚠️  Low token throughput: {avg_throughput:.1f} tokens/sec (target: >{TOKEN_THROUGHPUT_MIN}). "
                        "Consider: 1) Increase max-num-batched-tokens, "
                        "2) Enable tensor parallelism if multi-GPU, "
                        "3) Use smaller model or quantized version"
                    )
                else:
                    recommendations.append(
                        f"✅ Token throughput good: {avg_throughput:.1f} tokens/sec"
                    )
        
        # Check context window usage
        if "vllm:avg_prompt_throughput_toks_per_s" in self.metrics_history[-1]:
            prompt_throughput = self.metrics_history[-1]["vllm:avg_prompt_throughput_toks_per_s"]
            
            if prompt_throughput < 500:
                recommendations.append(
                    f"💡 Prompt processing slow: {prompt_throughput:.0f} tokens/sec. "
                    "Consider enabling prefix caching with --enable-prefix-caching"
                )
        
        return recommendations


class QdrantMonitor:
    """Monitors Qdrant vector database performance"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.query_times = []
        self.max_history = 50
    
    def get_collections(self) -> List[str]:
        """Get list of collections"""
        try:
            response = requests.get(
                f"{self.base_url}/collections",
                timeout=5
            )
            
            if response.status_code == 200:
                data = response.json()
                return [c["name"] for c in data.get("result", {}).get("collections", [])]
            
            return []
        except Exception as e:
            logger.error(f"Error fetching Qdrant collections: {e}")
            return []
    
    def test_query_performance(self, collection: str) -> Optional[float]:
        """Test query performance on a collection"""
        try:
            start_time = time.time()
            
            response = requests.post(
                f"{self.base_url}/collections/{collection}/points/search",
                json={
                    "vector": [0.1] * 384,  # Dummy vector
                    "limit": 5
                },
                timeout=10
            )
            
            query_time = time.time() - start_time
            
            if response.status_code == 200:
                self.query_times.append(query_time)
                if len(self.query_times) > self.max_history:
                    self.query_times.pop(0)
                
                return query_time
            
            return None
        except Exception as e:
            logger.error(f"Error testing Qdrant query: {e}")
            return None
    
    def get_qdrant_recommendations(self) -> List[str]:
        """Get recommendations for Qdrant optimization"""
        collections = self.get_collections()
        
        if not collections:
            return ["No Qdrant collections found"]
        
        recommendations = []
        recommendations.append(f"📊 Found {len(collections)} collection(s): {', '.join(collections)}")
        
        # Test query performance on each collection
        for collection in collections[:3]:  # Test first 3 collections
            query_time = self.test_query_performance(collection)
            
            if query_time:
                logger.info(f"Collection '{collection}' query time: {query_time:.3f}s")
                
                if query_time > SLOW_RESPONSE_THRESHOLD:
                    recommendations.append(
                        f"⚠️  Collection '{collection}' slow: {query_time:.2f}s. "
                        "Recommendations: "
                        "1) Create HNSW index if not exists, "
                        "2) Increase hnsw:m parameter (default 16, try 32), "
                        "3) Optimize collection with full indexing"
                    )
                else:
                    recommendations.append(
                        f"✅ Collection '{collection}' query fast: {query_time:.3f}s"
                    )
        
        # Check average query time
        if len(self.query_times) >= 5:
            avg_query_time = statistics.mean(self.query_times)
            
            if avg_query_time > SLOW_RESPONSE_THRESHOLD:
                recommendations.append(
                    f"💡 Average query time: {avg_query_time:.2f}s. "
                    "Consider: 1) Reducing vector dimensions, "
                    "2) Using quantization, "
                    "3) Increasing Qdrant memory allocation"
                )
        
        return recommendations


def generate_optimization_report(gpu: GPUMonitor, vllm: VLLMMonitor, qdrant: QdrantMonitor):
    """Generate comprehensive optimization report"""
    logger.info("\n" + "="*80)
    logger.info("AUTO-OPTIMIZATION REPORT")
    logger.info("="*80)
    
    # GPU recommendations
    logger.info("\n🎮 GPU / VRAM Optimization:")
    for rec in gpu.get_vram_recommendations():
        logger.info(f"  {rec}")
    
    # vLLM recommendations
    logger.info("\n⚡ vLLM Performance:")
    for rec in vllm.get_performance_recommendations():
        logger.info(f"  {rec}")
    
    # Qdrant recommendations
    logger.info("\n🔍 Qdrant Vector Database:")
    for rec in qdrant.get_qdrant_recommendations():
        logger.info(f"  {rec}")
    
    logger.info("\n" + "="*80 + "\n")


def main():
    """Main optimization loop"""
    logger.info("=== Auto-Optimization System Starting ===")
    logger.info(f"vLLM URL: {VLLM_URL}")
    logger.info(f"Qdrant URL: {QDRANT_URL}")
    logger.info(f"Check interval: {CHECK_INTERVAL}s")
    
    # Initialize monitors
    gpu = GPUMonitor()
    vllm = VLLMMonitor(VLLM_URL)
    qdrant = QdrantMonitor(QDRANT_URL)
    
    iteration = 0
    
    while True:
        try:
            iteration += 1
            logger.info(f"\n--- Optimization Check {iteration} ---")
            
            # Collect metrics
            gpu_stats = gpu.get_gpu_stats()
            vllm_metrics = vllm.get_metrics()
            
            if gpu_stats:
                logger.info(f"GPU: {gpu_stats['memory_usage_pct']:.1f}% VRAM, "
                          f"{gpu_stats['gpu_utilization_pct']:.1f}% utilization, "
                          f"{gpu_stats['temperature_c']:.1f}°C")
            
            # Every 10 iterations, generate full report
            if iteration % 10 == 0:
                generate_optimization_report(gpu, vllm, qdrant)
            
            # Sleep before next check
            time.sleep(CHECK_INTERVAL)
            
        except KeyboardInterrupt:
            logger.info("Shutting down gracefully...")
            break
        except Exception as e:
            logger.error(f"Error in optimization cycle: {e}", exc_info=True)
            time.sleep(60)


if __name__ == "__main__":
    main()

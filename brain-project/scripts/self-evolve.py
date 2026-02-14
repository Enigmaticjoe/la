#!/usr/bin/env python3
"""
Self-Evolution Engine - Continuously improves AI performance based on metrics

Monitors:
- Conversation quality ratings from OpenWebUI
- Response times and token usage
- Task-specific prompt effectiveness

Actions:
- Automatically adjusts LLM parameters (temperature, top_p, etc.)
- Updates prompt configurations when improvements found
- Logs all optimization decisions with reasoning
"""

import os
import sys
import json
import time
import logging
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from collections import defaultdict
import statistics

import requests
import yaml
import numpy as np

# Configuration
OPENWEBUI_URL = os.getenv("OPENWEBUI_URL", "http://openwebui:8080")
OPENWEBUI_API_KEY = os.getenv("OPENWEBUI_API_KEY", "")
VLLM_URL = os.getenv("VLLM_URL", "http://vllm:8000")
EVOLUTION_DB = os.getenv("EVOLUTION_DB", "/data/evolution/evolution.db")
EVOLUTION_LOG = os.getenv("EVOLUTION_LOG", "/data/evolution/evolution.log")
CHECK_INTERVAL = int(os.getenv("CHECK_INTERVAL", "300"))  # 5 minutes
MIN_SAMPLES = int(os.getenv("MIN_SAMPLES", "10"))  # Min conversations before optimization

# Parameter ranges for optimization
PARAM_RANGES = {
    "temperature": {"min": 0.1, "max": 1.5, "step": 0.05},
    "top_p": {"min": 0.7, "max": 0.99, "step": 0.02},
    "top_k": {"min": 10, "max": 100, "step": 5},
    "repetition_penalty": {"min": 1.0, "max": 1.3, "step": 0.05},
}

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(EVOLUTION_LOG),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("self-evolve")


class EvolutionDatabase:
    """Manages evolution metrics and decisions"""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        self._init_db()
    
    def _init_db(self):
        """Initialize database schema"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS metrics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    conversation_id TEXT,
                    model_name TEXT,
                    temperature REAL,
                    top_p REAL,
                    top_k INTEGER,
                    repetition_penalty REAL,
                    response_time REAL,
                    tokens_used INTEGER,
                    quality_rating REAL,
                    task_category TEXT,
                    prompt_hash TEXT
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS optimizations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    parameter TEXT,
                    old_value REAL,
                    new_value REAL,
                    reasoning TEXT,
                    expected_improvement REAL,
                    task_category TEXT
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS prompt_performance (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    prompt_hash TEXT,
                    task_category TEXT,
                    avg_quality REAL,
                    avg_response_time REAL,
                    sample_count INTEGER,
                    prompt_template TEXT
                )
            """)
            
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_metrics_timestamp 
                ON metrics(timestamp)
            """)
            
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_metrics_task 
                ON metrics(task_category)
            """)
            
            conn.commit()
    
    def record_metric(self, **kwargs):
        """Record a conversation metric"""
        with sqlite3.connect(self.db_path) as conn:
            placeholders = ', '.join(['?'] * len(kwargs))
            columns = ', '.join(kwargs.keys())
            sql = f"INSERT INTO metrics ({columns}) VALUES ({placeholders})"
            conn.execute(sql, list(kwargs.values()))
            conn.commit()
    
    def record_optimization(self, parameter: str, old_value: float, 
                          new_value: float, reasoning: str, 
                          expected_improvement: float, task_category: str = "general"):
        """Record an optimization decision"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO optimizations 
                (parameter, old_value, new_value, reasoning, expected_improvement, task_category)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (parameter, old_value, new_value, reasoning, expected_improvement, task_category))
            conn.commit()
    
    def get_recent_metrics(self, hours: int = 24, task_category: Optional[str] = None) -> List[Dict]:
        """Get recent metrics"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cutoff = datetime.now() - timedelta(hours=hours)
            
            if task_category:
                cursor = conn.execute("""
                    SELECT * FROM metrics 
                    WHERE timestamp > ? AND task_category = ?
                    ORDER BY timestamp DESC
                """, (cutoff, task_category))
            else:
                cursor = conn.execute("""
                    SELECT * FROM metrics 
                    WHERE timestamp > ?
                    ORDER BY timestamp DESC
                """, (cutoff,))
            
            return [dict(row) for row in cursor.fetchall()]
    
    def get_parameter_performance(self, parameter: str, task_category: Optional[str] = None) -> Dict:
        """Analyze performance by parameter value"""
        metrics = self.get_recent_metrics(hours=72, task_category=task_category)
        
        if len(metrics) < MIN_SAMPLES:
            return {}
        
        performance = defaultdict(lambda: {"quality": [], "response_time": []})
        
        for m in metrics:
            if m.get(parameter) is not None and m.get("quality_rating") is not None:
                value = round(m[parameter], 2)  # Round for grouping
                performance[value]["quality"].append(m["quality_rating"])
                performance[value]["response_time"].append(m["response_time"])
        
        # Calculate averages
        result = {}
        for value, data in performance.items():
            if len(data["quality"]) >= 3:  # Need at least 3 samples
                result[value] = {
                    "avg_quality": statistics.mean(data["quality"]),
                    "avg_response_time": statistics.mean(data["response_time"]),
                    "sample_count": len(data["quality"]),
                    "quality_std": statistics.stdev(data["quality"]) if len(data["quality"]) > 1 else 0
                }
        
        return result


class OpenWebUIMonitor:
    """Monitors OpenWebUI for conversation metrics"""
    
    def __init__(self, base_url: str, api_key: str):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.session = requests.Session()
        if api_key:
            self.session.headers.update({"Authorization": f"Bearer {api_key}"})
    
    def get_recent_conversations(self, limit: int = 100) -> List[Dict]:
        """Fetch recent conversations from OpenWebUI"""
        try:
            # Try to access OpenWebUI API (endpoint may vary based on version)
            response = self.session.get(
                f"{self.base_url}/api/v1/chats",
                params={"limit": limit},
                timeout=10
            )
            
            if response.status_code == 200:
                return response.json().get("data", [])
            else:
                logger.warning(f"Failed to fetch conversations: {response.status_code}")
                return []
        except Exception as e:
            logger.error(f"Error fetching conversations: {e}")
            return []
    
    def extract_metrics(self, conversation: Dict) -> Optional[Dict]:
        """Extract useful metrics from a conversation"""
        try:
            # Extract relevant data from conversation structure
            messages = conversation.get("messages", [])
            if not messages:
                return None
            
            # Calculate response time (if available)
            response_time = conversation.get("response_time", 0)
            
            # Get model parameters used
            model_config = conversation.get("model_config", {})
            temperature = model_config.get("temperature", 0.7)
            top_p = model_config.get("top_p", 0.9)
            
            # Quality rating (if user provided feedback)
            quality_rating = conversation.get("rating")
            
            # Token usage
            tokens_used = conversation.get("tokens_used", 0)
            
            # Task category detection (simple heuristic)
            task_category = self._detect_task_category(messages)
            
            return {
                "conversation_id": conversation.get("id"),
                "model_name": conversation.get("model"),
                "temperature": temperature,
                "top_p": top_p,
                "top_k": model_config.get("top_k", 40),
                "repetition_penalty": model_config.get("repetition_penalty", 1.1),
                "response_time": response_time,
                "tokens_used": tokens_used,
                "quality_rating": quality_rating,
                "task_category": task_category,
                "prompt_hash": self._hash_prompt(messages[0].get("content", ""))
            }
        except Exception as e:
            logger.error(f"Error extracting metrics: {e}")
            return None
    
    def _detect_task_category(self, messages: List[Dict]) -> str:
        """Detect task category from conversation"""
        if not messages:
            return "general"
        
        first_message = messages[0].get("content", "").lower()
        
        # Simple keyword-based categorization
        if any(kw in first_message for kw in ["code", "function", "debug", "program"]):
            return "coding"
        elif any(kw in first_message for kw in ["explain", "what is", "how does"]):
            return "explanation"
        elif any(kw in first_message for kw in ["create", "write", "generate"]):
            return "creation"
        elif any(kw in first_message for kw in ["summarize", "tldr", "summary"]):
            return "summarization"
        else:
            return "general"
    
    def _hash_prompt(self, prompt: str) -> str:
        """Create simple hash of prompt for tracking"""
        import hashlib
        return hashlib.md5(prompt.encode()).hexdigest()[:8]


class ParameterOptimizer:
    """Optimizes LLM parameters based on performance data"""
    
    def __init__(self, db: EvolutionDatabase):
        self.db = db
    
    def optimize_parameter(self, parameter: str, task_category: Optional[str] = None) -> Optional[Tuple[float, str]]:
        """
        Optimize a single parameter based on historical performance
        
        Returns: (new_value, reasoning) or None if no optimization needed
        """
        performance = self.db.get_parameter_performance(parameter, task_category)
        
        if len(performance) < 2:
            logger.info(f"Not enough data to optimize {parameter}")
            return None
        
        # Find value with best quality
        best_value = None
        best_quality = 0
        
        for value, metrics in performance.items():
            # Weight by quality and penalize high response time
            score = metrics["avg_quality"] - (metrics["avg_response_time"] / 100)
            
            if score > best_quality:
                best_quality = score
                best_value = value
        
        if best_value is None:
            return None
        
        # Get current average value
        recent_metrics = self.db.get_recent_metrics(hours=24, task_category=task_category)
        if not recent_metrics:
            return None
        
        current_values = [m[parameter] for m in recent_metrics if m.get(parameter) is not None]
        if not current_values:
            return None
        
        current_avg = statistics.mean(current_values)
        
        # Check if change is significant
        if abs(best_value - current_avg) < PARAM_RANGES[parameter]["step"]:
            logger.info(f"{parameter} already optimal at {current_avg:.2f}")
            return None
        
        # Build reasoning
        reasoning = (
            f"Analysis of {len(performance)} parameter values across {sum(p['sample_count'] for p in performance.values())} samples. "
            f"Value {best_value} shows avg quality {performance[best_value]['avg_quality']:.2f} "
            f"vs current avg {current_avg:.2f}. "
            f"Expected improvement: {(performance[best_value]['avg_quality'] - performance.get(current_avg, {}).get('avg_quality', 0)):.2f}"
        )
        
        expected_improvement = performance[best_value]['avg_quality'] - performance.get(current_avg, {}).get('avg_quality', 0)
        
        return best_value, reasoning, expected_improvement
    
    def apply_optimization(self, parameter: str, value: float, task_category: str = "general"):
        """Apply optimization to vLLM/OpenWebUI configuration"""
        # TODO: Implement actual configuration update via API
        # For now, just log the recommendation
        logger.info(f"OPTIMIZATION RECOMMENDED: Set {parameter}={value} for {task_category}")
        logger.info(f"Manual update required in OpenWebUI settings or vLLM config")


def main():
    """Main evolution loop"""
    logger.info("=== Self-Evolution Engine Starting ===")
    logger.info(f"OpenWebUI URL: {OPENWEBUI_URL}")
    logger.info(f"vLLM URL: {VLLM_URL}")
    logger.info(f"Check interval: {CHECK_INTERVAL}s")
    logger.info(f"Minimum samples: {MIN_SAMPLES}")
    
    # Initialize components
    db = EvolutionDatabase(EVOLUTION_DB)
    monitor = OpenWebUIMonitor(OPENWEBUI_URL, OPENWEBUI_API_KEY)
    optimizer = ParameterOptimizer(db)
    
    last_conversation_id = None
    iteration = 0
    
    while True:
        try:
            iteration += 1
            logger.info(f"\n--- Evolution Cycle {iteration} ---")
            
            # 1. Collect new conversation metrics
            conversations = monitor.get_recent_conversations(limit=50)
            new_metrics_count = 0
            
            for conv in conversations:
                conv_id = conv.get("id")
                
                # Skip if already processed
                if conv_id == last_conversation_id:
                    break
                
                metrics = monitor.extract_metrics(conv)
                if metrics and metrics.get("quality_rating") is not None:
                    db.record_metric(**metrics)
                    new_metrics_count += 1
            
            if conversations:
                last_conversation_id = conversations[0].get("id")
            
            logger.info(f"Collected {new_metrics_count} new conversation metrics")
            
            # 2. Analyze and optimize parameters
            task_categories = ["general", "coding", "explanation", "creation"]
            
            for category in task_categories:
                recent = db.get_recent_metrics(hours=72, task_category=category)
                
                if len(recent) < MIN_SAMPLES:
                    logger.info(f"Category '{category}': Only {len(recent)} samples, need {MIN_SAMPLES}")
                    continue
                
                logger.info(f"Analyzing category '{category}' with {len(recent)} samples")
                
                # Try optimizing each parameter
                for param in ["temperature", "top_p"]:
                    result = optimizer.optimize_parameter(param, task_category=category)
                    
                    if result:
                        new_value, reasoning, expected_improvement = result
                        
                        # Get current value
                        current_values = [m[param] for m in recent if m.get(param) is not None]
                        current_avg = statistics.mean(current_values) if current_values else 0
                        
                        # Log the optimization
                        logger.info(f"OPTIMIZATION FOUND: {param}")
                        logger.info(f"  Category: {category}")
                        logger.info(f"  Current: {current_avg:.2f}")
                        logger.info(f"  Optimal: {new_value:.2f}")
                        logger.info(f"  Expected improvement: {expected_improvement:.2f}")
                        logger.info(f"  Reasoning: {reasoning}")
                        
                        # Record in database
                        db.record_optimization(
                            parameter=param,
                            old_value=current_avg,
                            new_value=new_value,
                            reasoning=reasoning,
                            expected_improvement=expected_improvement,
                            task_category=category
                        )
                        
                        # Apply optimization
                        optimizer.apply_optimization(param, new_value, category)
            
            # 3. Sleep before next cycle
            logger.info(f"Sleeping for {CHECK_INTERVAL}s...")
            time.sleep(CHECK_INTERVAL)
            
        except KeyboardInterrupt:
            logger.info("Shutting down gracefully...")
            break
        except Exception as e:
            logger.error(f"Error in evolution cycle: {e}", exc_info=True)
            time.sleep(60)  # Wait a bit before retrying


if __name__ == "__main__":
    main()

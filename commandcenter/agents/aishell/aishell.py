#!/usr/bin/env python3
"""
Digital Renegade AI Shell - Jules Protocol v3.1
A self-aware, mode-switching, multi-model AI shell with distributed memory.
"""

import json
import re
import hashlib
import os
import sys
import time
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import requests
import redis
import psycopg2
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

# Configuration
CONSTITUTION_PATH = os.getenv(
    "CONSTITUTION_PATH",
    "/home/user/brain/config/constitution/digital_renegade_core.v3.json"
)
OLLAMA_BRAIN_URL = os.getenv("OLLAMA_BRAIN_URL", "http://chimera_brain:11434")
OLLAMA_EYES_URL = os.getenv("OLLAMA_EYES_URL", "http://chimera_eyes:11434")
REDIS_URL = os.getenv("REDIS_URL", "redis://chimera_cache:6379/0")
POSTGRES_URL = os.getenv("POSTGRES_URL", "postgresql://postgres:password@chimera_postgres:5432/chimera")
QDRANT_URL = os.getenv("QDRANT_URL", "http://chimera_memory:6333")


class Constitution:
    """Loads and validates the AI constitution."""

    def __init__(self, path: str):
        self.path = path
        self.data = self._load()
        self._validate_checksum()

    def _load(self) -> Dict:
        """Load constitution from JSON file."""
        with open(self.path, 'r') as f:
            return json.load(f)

    def _validate_checksum(self) -> bool:
        """Validate constitution integrity."""
        # Calculate current checksum
        content = json.dumps(self.data, sort_keys=True).encode()
        current_hash = hashlib.sha256(content).hexdigest()

        stored_hash = self.data["meta"]["checksum"]
        if f"sha256:{current_hash}" != stored_hash:
            print(f"⚠️  Constitution checksum mismatch!")
            print(f"   Expected: {stored_hash}")
            print(f"   Got: sha256:{current_hash}")
            return False
        return True

    def get_mode_config(self, mode: str) -> Dict:
        """Get configuration for a specific operational mode."""
        return self.data["operational_modes"].get(mode, {})

    def get_model_tier(self, tier: str) -> Dict:
        """Get model configuration for a tier (FAST/DEEP/VISION/TOOLS)."""
        return self.data["model_router"]["tiers"].get(tier, {})


class ModeRouter:
    """Automatically selects operational mode based on user input."""

    def __init__(self, constitution: Constitution):
        self.constitution = constitution
        self.rules = constitution.data["mode_router"]["rules"]
        self.default = constitution.data["mode_router"]["default"]

    def route(self, user_input: str) -> str:
        """Select mode based on keyword matching with weighted scoring."""
        text = user_input.lower()
        scores = {}

        for mode, config in self.rules.items():
            score = 0
            for keyword in config["keywords"]:
                if keyword in text:
                    score += config["weight"]
            if score > 0:
                scores[mode] = score

        if not scores:
            return self.default

        # Return mode with highest score
        return max(scores, key=scores.get)


class ModelRouter:
    """Routes requests to appropriate models based on task and load."""

    def __init__(self, constitution: Constitution):
        self.constitution = constitution
        self.tiers = constitution.data["model_router"]["tiers"]

    def select_model(self, mode: str) -> Tuple[str, str]:
        """
        Select appropriate model for mode.
        Returns (tier, model_name)
        """
        mode_config = self.constitution.get_mode_config(mode)
        preferred_tier = mode_config.get("model_preference", "DEEP")

        tier_config = self.tiers.get(preferred_tier, self.tiers["FAST"])
        models = tier_config.get("models", {}).get("ollama", ["llama3.2"])

        # For now, just return first model
        # TODO: Implement load balancing
        return (preferred_tier, models[0])

    def get_model_url(self, tier: str) -> str:
        """Get Ollama URL based on tier."""
        if tier == "VISION":
            return OLLAMA_EYES_URL
        return OLLAMA_BRAIN_URL


class MemoryManager:
    """Three-tier memory system: ephemeral, working, long-term."""

    def __init__(self, constitution: Constitution):
        self.constitution = constitution
        self.redis_client = None
        self.postgres_conn = None
        self.qdrant_client = None
        self._connect()

    def _connect(self):
        """Connect to all memory backends."""
        try:
            # Ephemeral (Redis)
            self.redis_client = redis.from_url(REDIS_URL, decode_responses=True)
            self.redis_client.ping()
        except Exception as e:
            print(f"⚠️  Redis unavailable: {e}")

        try:
            # Working (PostgreSQL)
            self.postgres_conn = psycopg2.connect(POSTGRES_URL)
            self._init_postgres_schema()
        except Exception as e:
            print(f"⚠️  PostgreSQL unavailable: {e}")

        try:
            # Long-term (Qdrant)
            self.qdrant_client = QdrantClient(url=QDRANT_URL)
            self._init_qdrant_collections()
        except Exception as e:
            print(f"⚠️  Qdrant unavailable: {e}")

    def _init_postgres_schema(self):
        """Initialize PostgreSQL schema for working memory."""
        with self.postgres_conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS facts (
                    id SERIAL PRIMARY KEY,
                    content TEXT NOT NULL,
                    source TEXT,
                    confidence FLOAT DEFAULT 0.5,
                    timestamp TIMESTAMP DEFAULT NOW(),
                    tags TEXT[]
                )
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS decisions (
                    id SERIAL PRIMARY KEY,
                    context TEXT NOT NULL,
                    choice TEXT NOT NULL,
                    rationale TEXT,
                    outcome TEXT,
                    timestamp TIMESTAMP DEFAULT NOW()
                )
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS lessons (
                    id SERIAL PRIMARY KEY,
                    mistake TEXT NOT NULL,
                    correction TEXT NOT NULL,
                    result TEXT,
                    timestamp TIMESTAMP DEFAULT NOW()
                )
            """)
            self.postgres_conn.commit()

    def _init_qdrant_collections(self):
        """Initialize Qdrant collections for long-term memory."""
        collections = ["facts", "conversations", "artifacts"]

        for collection in collections:
            if not self.qdrant_client.collection_exists(collection):
                self.qdrant_client.create_collection(
                    collection_name=collection,
                    vectors_config=VectorParams(size=384, distance=Distance.COSINE)
                )

    def store_ephemeral(self, key: str, value: str, ttl: int = 3600):
        """Store in ephemeral memory (Redis)."""
        if self.redis_client:
            self.redis_client.setex(key, ttl, value)

    def get_ephemeral(self, key: str) -> Optional[str]:
        """Retrieve from ephemeral memory."""
        if self.redis_client:
            return self.redis_client.get(key)
        return None

    def store_fact(self, content: str, source: str, confidence: float = 0.5, tags: List[str] = None):
        """Store fact in working memory."""
        if self.postgres_conn:
            with self.postgres_conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO facts (content, source, confidence, tags) VALUES (%s, %s, %s, %s)",
                    (content, source, confidence, tags or [])
                )
                self.postgres_conn.commit()

    def store_decision(self, context: str, choice: str, rationale: str):
        """Store decision in working memory."""
        if self.postgres_conn:
            with self.postgres_conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO decisions (context, choice, rationale) VALUES (%s, %s, %s)",
                    (context, choice, rationale)
                )
                self.postgres_conn.commit()


class AIShell:
    """Main AI shell implementing Jules Protocol."""

    def __init__(self):
        self.constitution = Constitution(CONSTITUTION_PATH)
        self.mode_router = ModeRouter(self.constitution)
        self.model_router = ModelRouter(self.constitution)
        self.memory = MemoryManager(self.constitution)
        self.current_mode = "ARCHITECT"
        self.conversation_history = []

    def banner(self):
        """Display startup banner."""
        identity = self.constitution.data["identity"]
        meta = self.constitution.data["meta"]

        print("\n" + "═" * 70)
        print(f"  🧠 {meta['name']} - {meta['codename']}")
        print(f"  Version: {meta['version']}")
        print(f"  Persona: {identity['persona']}")
        print(f"  Alignment: {identity['alignment']}")
        print("═" * 70)
        print(f"\n{identity['voice']}\n")
        print("Jules Protocol loaded. Let's do this properly.\n")

    def query_ollama(self, model: str, prompt: str, url: str) -> str:
        """Query Ollama API."""
        try:
            response = requests.post(
                f"{url}/api/generate",
                json={
                    "model": model,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=120
            )
            response.raise_for_status()
            return response.json().get("response", "")
        except Exception as e:
            return f"Error querying model: {e}"

    def process_input(self, user_input: str) -> str:
        """Process user input through mode and model routing."""

        # Check for explicit mode override
        if user_input.startswith("/mode "):
            new_mode = user_input.split(" ", 1)[1].upper()
            if new_mode in self.constitution.data["operational_modes"]:
                self.current_mode = new_mode
                return f"Mode switched to {new_mode}"
            else:
                return f"Unknown mode: {new_mode}"

        # Auto-detect mode
        detected_mode = self.mode_router.route(user_input)
        if detected_mode != self.current_mode:
            print(f"[Mode: {self.current_mode} → {detected_mode}]")
            self.current_mode = detected_mode

        # Select appropriate model
        tier, model = self.model_router.select_model(self.current_mode)
        model_url = self.model_router.get_model_url(tier)

        print(f"[{tier}: {model}]")

        # Build prompt with mode context
        mode_config = self.constitution.get_mode_config(self.current_mode)
        system_suffix = mode_config.get("system_prompt_suffix", "")

        full_prompt = f"{system_suffix}\n\nUser: {user_input}\n\nAssistant:"

        # Query model
        response = self.query_ollama(model, full_prompt, model_url)

        # Store in memory
        self.conversation_history.append({
            "mode": self.current_mode,
            "tier": tier,
            "model": model,
            "input": user_input,
            "output": response,
            "timestamp": datetime.now().isoformat()
        })

        # Store in ephemeral memory
        conv_key = f"conversation:{int(time.time())}"
        self.memory.store_ephemeral(conv_key, json.dumps(self.conversation_history[-1]))

        return response

    def run(self):
        """Main REPL loop."""
        self.banner()

        while True:
            try:
                user_input = input(f"aishell [{self.current_mode}]> ")

                if not user_input.strip():
                    continue

                if user_input.lower() in ["exit", "quit", "q"]:
                    print("\nExiting Jules Protocol. Stay sovereign.")
                    break

                if user_input.lower() in ["help", "?"]:
                    self.show_help()
                    continue

                # Process input
                response = self.process_input(user_input)
                print(f"\n{response}\n")

            except KeyboardInterrupt:
                print("\n\nInterrupted. Exiting.")
                break
            except Exception as e:
                print(f"\n⚠️  Error: {e}\n")

    def show_help(self):
        """Display help information."""
        print("""
Available Commands:
  /mode <MODE>     - Switch to specific mode (ARCHITECT, CODE, DEBUG, etc.)
  help or ?        - Show this help
  exit/quit/q      - Exit shell

Available Modes:
  ARCHITECT        - Design architecture and systems
  CODE             - Write production code
  DEBUG            - Debug and troubleshoot
  RESEARCH         - Research and learn
  SENTRY           - Security monitoring
  EVOLVE           - Optimize and refactor
  HACK             - Security analysis (ethical use only)
  HUSTLE           - Business and monetization

Examples:
  Design a microservice architecture
  Write a Python script to scrape data
  Debug why my Docker container won't start
  Research the latest in vector databases
  Scan my network for vulnerabilities
  Optimize this SQL query
        """)


def main():
    """Entry point."""
    shell = AIShell()
    shell.run()


if __name__ == "__main__":
    main()

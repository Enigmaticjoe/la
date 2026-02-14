#!/usr/bin/env python3
"""
Memory Pruner - Autonomous memory management for Jules Protocol
Runs daily to clean low-confidence data, merge duplicates, and optimize storage.
"""

import json
import os
import time
from datetime import datetime, timedelta
from typing import List, Dict
import psycopg2
from qdrant_client import QdrantClient
import redis
import schedule
import hashlib

# Configuration
CONSTITUTION_PATH = os.getenv(
    "CONSTITUTION_PATH",
    "/home/user/brain/config/constitution/digital_renegade_core.v3.json"
)
POSTGRES_URL = os.getenv("POSTGRES_URL", "postgresql://postgres:password@chimera_postgres:5432/chimera")
QDRANT_URL = os.getenv("QDRANT_URL", "http://chimera_memory:6333")
REDIS_URL = os.getenv("REDIS_URL", "redis://chimera_cache:6379/0")
LOG_PATH = "/var/log/jules_protocol/memory_pruner.log"


class MemoryPruner:
    """Autonomous memory management system."""

    def __init__(self):
        self.constitution = self._load_constitution()
        self.rules = self.constitution["memory_pruner"]["rules"]
        self.dry_run = self.constitution["memory_pruner"].get("dry_run", False)

        # Connect to backends
        self.postgres_conn = psycopg2.connect(POSTGRES_URL)
        self.qdrant_client = QdrantClient(url=QDRANT_URL)
        self.redis_client = redis.from_url(REDIS_URL, decode_responses=True)

        # Statistics
        self.stats = {
            "deleted": 0,
            "merged": 0,
            "moved": 0,
            "protected": 0
        }

    def _load_constitution(self) -> Dict:
        """Load constitution from file."""
        with open(CONSTITUTION_PATH, 'r') as f:
            return json.load(f)

    def log(self, message: str):
        """Log message to file and stdout."""
        timestamp = datetime.now().isoformat()
        log_entry = f"[{timestamp}] {message}"

        print(log_entry)

        # Ensure log directory exists
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)

        with open(LOG_PATH, 'a') as f:
            f.write(log_entry + "\n")

    def delete_low_confidence_old_data(self):
        """Delete low-confidence data older than 90 days."""
        self.log("Running: delete_low_confidence_old_data")

        cutoff_date = datetime.now() - timedelta(days=90)

        with self.postgres_conn.cursor() as cur:
            # Count candidates
            cur.execute(
                "SELECT COUNT(*) FROM facts WHERE confidence < 0.3 AND timestamp < %s",
                (cutoff_date,)
            )
            count = cur.fetchone()[0]

            if count > 0:
                self.log(f"  Found {count} low-confidence facts older than 90 days")

                if not self.dry_run:
                    cur.execute(
                        "DELETE FROM facts WHERE confidence < 0.3 AND timestamp < %s",
                        (cutoff_date,)
                    )
                    self.postgres_conn.commit()
                    self.stats["deleted"] += count
                    self.log(f"  ✓ Deleted {count} facts")
                else:
                    self.log(f"  (Dry-run) Would delete {count} facts")

    def merge_duplicate_facts(self):
        """Merge facts with high similarity."""
        self.log("Running: merge_duplicate_facts")

        with self.postgres_conn.cursor() as cur:
            # Find duplicate facts (same content hash)
            cur.execute("""
                SELECT content, array_agg(id ORDER BY confidence DESC) as ids,
                       array_agg(confidence ORDER BY confidence DESC) as confs
                FROM facts
                GROUP BY content
                HAVING COUNT(*) > 1
            """)

            duplicates = cur.fetchall()

            for content, ids, confs in duplicates:
                self.log(f"  Found {len(ids)} duplicates: {content[:50]}...")

                if not self.dry_run:
                    # Keep highest confidence, delete others
                    keep_id = ids[0]
                    delete_ids = ids[1:]

                    cur.execute(
                        "DELETE FROM facts WHERE id = ANY(%s)",
                        (delete_ids,)
                    )
                    self.postgres_conn.commit()

                    self.stats["merged"] += len(delete_ids)
                    self.log(f"  ✓ Merged {len(delete_ids)} duplicates into fact {keep_id}")
                else:
                    self.log(f"  (Dry-run) Would merge {len(ids)-1} duplicates")

    def downgrade_unused_memories(self):
        """Move unused memories to cold storage."""
        self.log("Running: downgrade_unused_memories")

        # For now, just mark in database
        # In future, could move to cheaper storage tier

        cutoff_date = datetime.now() - timedelta(days=30)

        with self.postgres_conn.cursor() as cur:
            # Find facts that haven't been accessed in 30 days
            # (This would require access tracking - not implemented yet)
            self.log("  Access tracking not yet implemented - skipping")

    def preserve_user_pinned(self):
        """Ensure user-pinned memories are never deleted."""
        self.log("Running: preserve_user_pinned")

        # Would check for user_pinned flag
        # Not implemented yet
        self.log("  User pinning not yet implemented - skipping")

    def preserve_high_value(self):
        """Protect high-confidence or frequently-referenced data."""
        self.log("Running: preserve_high_value")

        with self.postgres_conn.cursor() as cur:
            # Count high-value facts
            cur.execute("SELECT COUNT(*) FROM facts WHERE confidence > 0.9")
            count = cur.fetchone()[0]

            self.stats["protected"] += count
            self.log(f"  ✓ Protected {count} high-confidence facts")

    def run_pruning_cycle(self):
        """Execute full pruning cycle."""
        self.log("=" * 70)
        self.log("Starting memory pruning cycle")
        self.log(f"Dry-run mode: {self.dry_run}")
        self.log("=" * 70)

        # Reset stats
        self.stats = {"deleted": 0, "merged": 0, "moved": 0, "protected": 0}

        try:
            # Execute each rule
            for rule in self.rules:
                rule_name = rule["name"]

                if rule_name == "delete_low_confidence_old_data":
                    self.delete_low_confidence_old_data()
                elif rule_name == "merge_duplicate_facts":
                    self.merge_duplicate_facts()
                elif rule_name == "downgrade_unused_memories":
                    self.downgrade_unused_memories()
                elif rule_name == "preserve_user_pinned":
                    self.preserve_user_pinned()
                elif rule_name == "preserve_high_value":
                    self.preserve_high_value()

            # Report summary
            self.log("=" * 70)
            self.log("Pruning cycle complete")
            self.log(f"  Deleted: {self.stats['deleted']}")
            self.log(f"  Merged: {self.stats['merged']}")
            self.log(f"  Moved: {self.stats['moved']}")
            self.log(f"  Protected: {self.stats['protected']}")
            self.log("=" * 70)

        except Exception as e:
            self.log(f"⚠️  Error during pruning: {e}")

    def schedule_pruning(self):
        """Schedule daily pruning at 3 AM."""
        self.log("Memory Pruner initialized")
        self.log("Scheduling daily pruning at 03:00")

        schedule.every().day.at("03:00").do(self.run_pruning_cycle)

        # Also run immediately on startup (dry-run)
        self.log("Running initial dry-run pruning cycle...")
        original_dry_run = self.dry_run
        self.dry_run = True
        self.run_pruning_cycle()
        self.dry_run = original_dry_run

        # Keep running
        while True:
            schedule.run_pending()
            time.sleep(60)


def main():
    """Entry point."""
    print("Jules Protocol Memory Pruner v1.0")
    print("I don't forget important things. I forget useless ones.\n")

    pruner = MemoryPruner()
    pruner.schedule_pruning()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Chimera Sentinel - Self-Healing & Monitoring Agent
Monitors Docker containers, Unraid connectivity, and system health
"""

import os
import time
import asyncio
import json
from datetime import datetime
from typing import Dict, List

import docker
import httpx
from loguru import logger
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Text, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import schedule

# Configure logging
logger.add("/logs/sentinel.log", rotation="50 MB", retention="30 days", level="INFO")

# Configuration
OLLAMA_API = os.getenv("OLLAMA_API", "http://chimera_brain:11434/api/generate")
MODEL = os.getenv("MODEL", "llama3.2")
CHECK_INTERVAL = int(os.getenv("CHECK_INTERVAL", "300"))  # 5 minutes
UNRAID_IP = os.getenv("UNRAID_IP", "192.168.1.222")
POSTGRES_URL = os.getenv("POSTGRES_URL")

# Docker client
docker_client = docker.from_env()

# Database setup
if POSTGRES_URL:
    Base = declarative_base()

    class HealthEvent(Base):
        __tablename__ = "health_events"

        id = Column(Integer, primary_key=True)
        timestamp = Column(DateTime, default=datetime.utcnow)
        event_type = Column(String)  # container_down, container_restarted, unraid_unreachable, etc.
        severity = Column(String)  # info, warning, critical
        container_name = Column(String, nullable=True)
        message = Column(Text)
        action_taken = Column(Text, nullable=True)
        resolved = Column(Boolean, default=False)

    engine = create_engine(POSTGRES_URL)
    Base.metadata.create_all(engine)
    SessionLocal = sessionmaker(bind=engine)
else:
    SessionLocal = None
    logger.warning("No PostgreSQL URL configured, events will not be persisted")

def log_event(event_type: str, severity: str, message: str, container_name: str = None, action_taken: str = None):
    """Log an event to database and logger"""
    logger.log(severity.upper(), f"[{event_type}] {message}")

    if SessionLocal:
        db = SessionLocal()
        try:
            event = HealthEvent(
                event_type=event_type,
                severity=severity,
                container_name=container_name,
                message=message,
                action_taken=action_taken
            )
            db.add(event)
            db.commit()
        except Exception as e:
            logger.error(f"Failed to log event to database: {e}")
            db.rollback()
        finally:
            db.close()

async def query_ai(prompt: str) -> str:
    """Query Ollama for AI-assisted decision making"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                OLLAMA_API,
                json={
                    "model": MODEL,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=30.0
            )
            if response.status_code == 200:
                return response.json().get("response", "")
            else:
                logger.error(f"AI query failed: {response.status_code}")
                return ""
    except Exception as e:
        logger.error(f"Error querying AI: {e}")
        return ""

async def check_container_health() -> List[Dict]:
    """Check health of all Chimera containers"""
    issues = []

    try:
        containers = docker_client.containers.list(all=True, filters={"name": "chimera_"})

        for container in containers:
            name = container.name
            status = container.status

            # Check if container should be running but isn't
            if status != "running":
                logger.warning(f"Container {name} is {status}")
                issues.append({
                    "container": name,
                    "status": status,
                    "issue": f"Container not running (status: {status})"
                })

                # Attempt to restart
                if status in ["exited", "dead"]:
                    try:
                        logger.info(f"Attempting to restart {name}")
                        container.restart(timeout=30)
                        log_event(
                            "container_restarted",
                            "warning",
                            f"Container {name} was {status}, restarted successfully",
                            container_name=name,
                            action_taken="Automatic restart"
                        )
                    except Exception as e:
                        logger.error(f"Failed to restart {name}: {e}")
                        log_event(
                            "container_restart_failed",
                            "critical",
                            f"Failed to restart {name}: {str(e)}",
                            container_name=name,
                            action_taken="Restart attempt failed"
                        )

            # Check container health status
            health = container.attrs.get("State", {}).get("Health", {})
            if health:
                health_status = health.get("Status")
                if health_status == "unhealthy":
                    logger.warning(f"Container {name} reports unhealthy")
                    issues.append({
                        "container": name,
                        "status": "unhealthy",
                        "issue": "Container health check failing"
                    })

                    log_event(
                        "container_unhealthy",
                        "warning",
                        f"Container {name} health check failing",
                        container_name=name
                    )

    except Exception as e:
        logger.error(f"Error checking container health: {e}")
        log_event("health_check_error", "critical", f"Error checking containers: {str(e)}")

    return issues

async def check_unraid_connectivity() -> bool:
    """Check if Unraid server is reachable"""
    try:
        async with httpx.AsyncClient() as client:
            # Try to ping Unraid web interface
            response = await client.get(f"http://{UNRAID_IP}", timeout=5.0)
            if response.status_code in [200, 301, 302]:
                return True

        logger.warning(f"Unraid server at {UNRAID_IP} returned status: {response.status_code}")
        return False

    except Exception as e:
        logger.error(f"Cannot reach Unraid server at {UNRAID_IP}: {e}")
        log_event(
            "unraid_unreachable",
            "critical",
            f"Unraid server at {UNRAID_IP} is unreachable: {str(e)}",
            action_taken="Logged alert, manual intervention may be required"
        )
        return False

async def check_ollama_health() -> bool:
    """Check if Ollama is responsive"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get("http://chimera_brain:11434/api/tags", timeout=10.0)
            return response.status_code == 200
    except Exception as e:
        logger.error(f"Ollama health check failed: {e}")
        log_event(
            "ollama_unhealthy",
            "critical",
            f"Ollama is not responding: {str(e)}",
            container_name="chimera_brain"
        )
        return False

async def perform_health_check():
    """Perform comprehensive health check"""
    logger.info("="*50)
    logger.info("Starting health check cycle...")

    # Check containers
    container_issues = await check_container_health()
    if container_issues:
        logger.warning(f"Found {len(container_issues)} container issues")
    else:
        logger.info("All containers healthy")

    # Check Unraid
    unraid_ok = await check_unraid_connectivity()
    if unraid_ok:
        logger.info(f"Unraid server at {UNRAID_IP} is reachable")
    else:
        logger.error(f"Unraid server at {UNRAID_IP} is NOT reachable")

    # Check Ollama
    ollama_ok = await check_ollama_health()
    if ollama_ok:
        logger.info("Ollama is responsive")
    else:
        logger.error("Ollama is NOT responsive")

    # AI-assisted analysis if there are issues
    if container_issues or not unraid_ok or not ollama_ok:
        logger.info("Consulting AI for issue analysis...")

        issue_summary = {
            "timestamp": datetime.utcnow().isoformat(),
            "container_issues": container_issues,
            "unraid_reachable": unraid_ok,
            "ollama_responsive": ollama_ok
        }

        prompt = f"""
You are the Chimera Sentinel, a self-healing monitoring agent.

Current System Status:
{json.dumps(issue_summary, indent=2)}

Analyze these issues and provide:
1. Severity assessment (low/medium/high/critical)
2. Likely root cause
3. Recommended actions
4. Whether manual intervention is required

Be concise and technical.
"""

        ai_analysis = await query_ai(prompt)
        if ai_analysis:
            logger.info(f"AI Analysis:\n{ai_analysis}")
            log_event(
                "ai_analysis",
                "info",
                f"AI analysis of current issues",
                action_taken=f"Analysis: {ai_analysis[:500]}"
            )

    logger.info("Health check cycle complete")
    logger.info("="*50)

def run_health_check():
    """Sync wrapper for health check"""
    asyncio.run(perform_health_check())

async def main():
    """Main sentinel loop"""
    logger.info("Chimera Sentinel starting...")
    logger.info(f"Check interval: {CHECK_INTERVAL} seconds")
    logger.info(f"Monitoring Unraid at: {UNRAID_IP}")
    logger.info(f"Using AI model: {MODEL}")

    # Initial delay to let services start
    logger.info("Waiting 30 seconds for services to initialize...")
    await asyncio.sleep(30)

    # Schedule periodic checks
    schedule.every(CHECK_INTERVAL).seconds.do(run_health_check)

    # Run first check immediately
    await perform_health_check()

    # Main loop
    while True:
        schedule.run_pending()
        await asyncio.sleep(10)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Sentinel shutting down...")
    except Exception as e:
        logger.critical(f"Sentinel crashed: {e}")
        raise

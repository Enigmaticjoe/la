#!/usr/bin/env python3
"""
ROCm GPU Control Utilities

Provides functions to query and control AMD GPUs via rocm-smi command-line tool.
"""

import os
import re
import subprocess
import logging
from typing import Dict, List, Optional, Any
from pathlib import Path

logger = logging.getLogger(__name__)

# Default ROCm paths
ROCM_SMI_PATHS = [
    '/opt/rocm/bin/rocm-smi',
    '/opt/rocm-*/bin/rocm-smi',
    '/usr/bin/rocm-smi'
]


def find_rocm_smi() -> Optional[str]:
    """Find rocm-smi executable path."""
    for path_pattern in ROCM_SMI_PATHS:
        if '*' in path_pattern:
            # Handle wildcard paths
            import glob
            matches = glob.glob(path_pattern)
            if matches:
                path = matches[0]
                if os.path.isfile(path) and os.access(path, os.X_OK):
                    return path
        else:
            if os.path.isfile(path_pattern) and os.access(path_pattern, os.X_OK):
                return path_pattern
    
    # Try which command
    try:
        result = subprocess.run(['which', 'rocm-smi'], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    
    return None


def run_rocm_smi(args: List[str], timeout: int = 10) -> Optional[str]:
    """
    Run rocm-smi command with given arguments.
    
    Args:
        args: List of command arguments
        timeout: Command timeout in seconds
        
    Returns:
        Command output or None on error
    """
    rocm_smi = find_rocm_smi()
    
    if not rocm_smi:
        logger.warning("rocm-smi not found")
        return None
    
    try:
        cmd = [rocm_smi] + args
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False
        )
        
        if result.returncode == 0:
            return result.stdout
        else:
            logger.error(f"rocm-smi error: {result.stderr}")
            return None
            
    except subprocess.TimeoutExpired:
        logger.error(f"rocm-smi command timed out after {timeout}s")
        return None
    except Exception as e:
        logger.error(f"Error running rocm-smi: {e}")
        return None


def parse_gpu_info(output: str) -> List[Dict[str, Any]]:
    """
    Parse GPU information from rocm-smi output.
    
    Args:
        output: rocm-smi command output
        
    Returns:
        List of GPU info dictionaries
    """
    gpus = []
    
    try:
        lines = output.strip().split('\n')
        current_gpu = None
        
        for line in lines:
            line = line.strip()
            
            # GPU device line
            if line.startswith('GPU['):
                match = re.match(r'GPU\[(\d+)\]', line)
                if match:
                    if current_gpu:
                        gpus.append(current_gpu)
                    current_gpu = {'id': int(match.group(1))}
            
            # Temperature
            elif 'Temperature' in line and current_gpu is not None:
                match = re.search(r'(\d+\.?\d*)\s*[Cc]', line)
                if match:
                    current_gpu['temperature'] = float(match.group(1))
            
            # Memory usage
            elif 'Memory' in line and 'Used' in line and current_gpu is not None:
                match = re.search(r'(\d+)\s*MB\s*/\s*(\d+)\s*MB', line)
                if match:
                    current_gpu['vram_used_mb'] = int(match.group(1))
                    current_gpu['vram_total_mb'] = int(match.group(2))
            
            # GPU utilization
            elif 'GPU use' in line and current_gpu is not None:
                match = re.search(r'(\d+)\s*%', line)
                if match:
                    current_gpu['utilization'] = int(match.group(1))
            
            # Clock speed
            elif 'sclk' in line.lower() and current_gpu is not None:
                match = re.search(r'(\d+)\s*MHz', line)
                if match:
                    current_gpu['clock_mhz'] = int(match.group(1))
            
            # Fan speed
            elif 'fan' in line.lower() and current_gpu is not None:
                match = re.search(r'(\d+\.?\d*)\s*%', line)
                if match:
                    current_gpu['fan_speed_percent'] = float(match.group(1))
            
            # Power consumption
            elif 'power' in line.lower() and 'average' in line.lower() and current_gpu is not None:
                match = re.search(r'(\d+\.?\d*)\s*W', line)
                if match:
                    current_gpu['power_watts'] = float(match.group(1))
        
        # Add last GPU
        if current_gpu:
            gpus.append(current_gpu)
            
    except Exception as e:
        logger.error(f"Error parsing GPU info: {e}")
    
    return gpus


def get_gpu_stats() -> Dict[str, Any]:
    """
    Get comprehensive GPU statistics.
    
    Returns:
        Dictionary with GPU statistics
    """
    try:
        # Run rocm-smi with showuse and showtemp flags
        output = run_rocm_smi(['--showuse', '--showtemp', '--showmeminfo', 'vram'])
        
        if not output:
            return {
                'available': False,
                'error': 'Unable to get GPU stats',
                'gpus': []
            }
        
        gpus = parse_gpu_info(output)
        
        return {
            'available': True,
            'gpu_count': len(gpus),
            'gpus': gpus
        }
        
    except Exception as e:
        logger.error(f"Error getting GPU stats: {e}")
        return {
            'available': False,
            'error': str(e),
            'gpus': []
        }


def get_gpu_temperature(gpu_id: int = 0) -> Optional[float]:
    """
    Get temperature for specific GPU.
    
    Args:
        gpu_id: GPU device ID
        
    Returns:
        Temperature in Celsius or None
    """
    try:
        output = run_rocm_smi(['-d', str(gpu_id), '--showtemp'])
        
        if output:
            match = re.search(r'(\d+\.?\d*)\s*[Cc]', output)
            if match:
                return float(match.group(1))
        
        return None
        
    except Exception as e:
        logger.error(f"Error getting GPU temperature: {e}")
        return None


def get_gpu_vram(gpu_id: int = 0) -> Optional[Dict[str, int]]:
    """
    Get VRAM usage for specific GPU.
    
    Args:
        gpu_id: GPU device ID
        
    Returns:
        Dictionary with used and total VRAM in MB
    """
    try:
        output = run_rocm_smi(['-d', str(gpu_id), '--showmeminfo', 'vram'])
        
        if output:
            match = re.search(r'(\d+)\s*MB\s*/\s*(\d+)\s*MB', output)
            if match:
                return {
                    'used_mb': int(match.group(1)),
                    'total_mb': int(match.group(2)),
                    'percent': (int(match.group(1)) / int(match.group(2))) * 100
                }
        
        return None
        
    except Exception as e:
        logger.error(f"Error getting GPU VRAM: {e}")
        return None


def get_gpu_utilization(gpu_id: int = 0) -> Optional[int]:
    """
    Get GPU utilization percentage.
    
    Args:
        gpu_id: GPU device ID
        
    Returns:
        Utilization percentage or None
    """
    try:
        output = run_rocm_smi(['-d', str(gpu_id), '--showuse'])
        
        if output:
            match = re.search(r'(\d+)\s*%', output)
            if match:
                return int(match.group(1))
        
        return None
        
    except Exception as e:
        logger.error(f"Error getting GPU utilization: {e}")
        return None


def set_fan_speed(gpu_id: int, speed_percent: int) -> bool:
    """
    Set fan speed for specific GPU.
    
    Args:
        gpu_id: GPU device ID
        speed_percent: Fan speed percentage (0-100)
        
    Returns:
        True if successful, False otherwise
    """
    try:
        if not 0 <= speed_percent <= 100:
            logger.error(f"Invalid fan speed: {speed_percent}%")
            return False
        
        output = run_rocm_smi(['-d', str(gpu_id), '--setfan', str(speed_percent)])
        
        if output is not None:
            logger.info(f"Set GPU {gpu_id} fan speed to {speed_percent}%")
            return True
        
        return False
        
    except Exception as e:
        logger.error(f"Error setting fan speed: {e}")
        return False


def set_power_cap(gpu_id: int, power_watts: int) -> bool:
    """
    Set power cap for specific GPU.
    
    Args:
        gpu_id: GPU device ID
        power_watts: Power cap in watts
        
    Returns:
        True if successful, False otherwise
    """
    try:
        output = run_rocm_smi(['-d', str(gpu_id), '--setpoweroverdrive', str(power_watts)])
        
        if output is not None:
            logger.info(f"Set GPU {gpu_id} power cap to {power_watts}W")
            return True
        
        return False
        
    except Exception as e:
        logger.error(f"Error setting power cap: {e}")
        return False


def reset_gpu(gpu_id: int) -> bool:
    """
    Reset GPU to default settings.
    
    Args:
        gpu_id: GPU device ID
        
    Returns:
        True if successful, False otherwise
    """
    try:
        output = run_rocm_smi(['-d', str(gpu_id), '--resetclocks'])
        
        if output is not None:
            logger.info(f"Reset GPU {gpu_id} to default settings")
            return True
        
        return False
        
    except Exception as e:
        logger.error(f"Error resetting GPU: {e}")
        return False


def get_gpu_clocks(gpu_id: int = 0) -> Optional[Dict[str, int]]:
    """
    Get GPU clock speeds.
    
    Args:
        gpu_id: GPU device ID
        
    Returns:
        Dictionary with clock speeds in MHz
    """
    try:
        output = run_rocm_smi(['-d', str(gpu_id), '--showclock'])
        
        if not output:
            return None
        
        clocks = {}
        
        # Parse sclk (system clock)
        match = re.search(r'sclk.*?(\d+)\s*MHz', output, re.IGNORECASE)
        if match:
            clocks['sclk_mhz'] = int(match.group(1))
        
        # Parse mclk (memory clock)
        match = re.search(r'mclk.*?(\d+)\s*MHz', output, re.IGNORECASE)
        if match:
            clocks['mclk_mhz'] = int(match.group(1))
        
        return clocks if clocks else None
        
    except Exception as e:
        logger.error(f"Error getting GPU clocks: {e}")
        return None


def get_driver_version() -> Optional[str]:
    """
    Get ROCm driver version.
    
    Returns:
        Driver version string or None
    """
    try:
        output = run_rocm_smi(['--showdriverversion'])
        
        if output:
            match = re.search(r'Driver version:\s*(\S+)', output)
            if match:
                return match.group(1)
        
        return None
        
    except Exception as e:
        logger.error(f"Error getting driver version: {e}")
        return None


if __name__ == '__main__':
    # Test functions
    logging.basicConfig(level=logging.INFO)
    
    print("Testing ROCm control functions...")
    print(f"ROCm SMI path: {find_rocm_smi()}")
    print(f"Driver version: {get_driver_version()}")
    print("\nGPU Statistics:")
    print(get_gpu_stats())

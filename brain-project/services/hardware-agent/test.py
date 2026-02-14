#!/usr/bin/env python3
"""
Test script for hardware monitoring agent components.
"""

import sys
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def test_rocm_control():
    """Test ROCm control functions."""
    print("\n=== Testing ROCm Control ===")
    try:
        from rocm_control import (
            find_rocm_smi,
            get_gpu_stats,
            get_gpu_temperature,
            get_gpu_vram,
            get_driver_version
        )
        
        smi_path = find_rocm_smi()
        print(f"ROCm SMI Path: {smi_path}")
        
        if smi_path:
            print(f"Driver Version: {get_driver_version()}")
            
            stats = get_gpu_stats()
            print(f"GPU Stats: {stats}")
            
            if stats.get('available') and stats.get('gpus'):
                gpu_id = stats['gpus'][0].get('id', 0)
                print(f"GPU {gpu_id} Temperature: {get_gpu_temperature(gpu_id)}")
                print(f"GPU {gpu_id} VRAM: {get_gpu_vram(gpu_id)}")
        else:
            print("ROCm not available")
        
        print("✓ ROCm control tests passed")
        return True
        
    except Exception as e:
        print(f"✗ ROCm control tests failed: {e}")
        return False


def test_metrics_collector():
    """Test metrics collector."""
    print("\n=== Testing Metrics Collector ===")
    try:
        from metrics import MetricsCollector
        import time
        import tempfile
        import shutil
        
        # Create temporary directory
        temp_dir = tempfile.mkdtemp()
        
        try:
            collector = MetricsCollector(
                data_dir=temp_dir,
                interval=2,
                retention_days=1
            )
            
            print(f"Created collector with data dir: {temp_dir}")
            
            # Collect some metrics
            metrics = collector._collect_metrics()
            print(f"Collected metrics: CPU={metrics['cpu'].get('cpu_percent_avg', 0):.1f}%, "
                  f"Memory={metrics['memory'].get('percent', 0):.1f}%")
            
            # Store metrics
            collector._store_metrics(metrics)
            
            # Start collector
            collector.start()
            time.sleep(5)
            
            # Get recent metrics
            recent = collector.get_recent_metrics(minutes=1)
            print(f"Recent metrics count: {len(recent)}")
            
            # Stop collector
            collector.stop()
            
            print("✓ Metrics collector tests passed")
            return True
            
        finally:
            # Cleanup
            shutil.rmtree(temp_dir, ignore_errors=True)
        
    except Exception as e:
        print(f"✗ Metrics collector tests failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_optimizer():
    """Test optimizer."""
    print("\n=== Testing Optimizer ===")
    try:
        from optimizer import HardwareOptimizer
        
        optimizer = HardwareOptimizer()
        
        # Test performance score
        score = optimizer.get_performance_score()
        print(f"Performance Score: {score['score']}/100 ({score['rating']})")
        
        # Test recommendations
        recommendations = optimizer.get_recommendations()
        print(f"Recommendations: {recommendations['recommendation_count']} total, "
              f"{recommendations['critical_count']} critical, "
              f"{recommendations['warning_count']} warnings")
        
        # Test GPU utilization analysis
        gpu_data = [
            {'utilization': 50, 'temperature': 70},
            {'utilization': 60, 'temperature': 75},
            {'utilization': 55, 'temperature': 72}
        ]
        util_recs = optimizer.analyze_gpu_utilization(gpu_data)
        print(f"GPU utilization recommendations: {len(util_recs)}")
        
        print("✓ Optimizer tests passed")
        return True
        
    except Exception as e:
        print(f"✗ Optimizer tests failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_api_endpoints():
    """Test Flask API (basic import test)."""
    print("\n=== Testing API Endpoints ===")
    try:
        from monitor import app, load_config
        
        config = load_config()
        print(f"Config loaded: monitoring interval = {config['monitoring']['interval']}s")
        
        # Test app creation
        print(f"Flask app created: {app.name}")
        
        # List endpoints
        with app.app_context():
            routes = [rule.rule for rule in app.url_map.iter_rules()]
            print(f"Available endpoints: {len(routes)}")
            for route in sorted(routes):
                if not route.startswith('/static'):
                    print(f"  - {route}")
        
        print("✓ API endpoint tests passed")
        return True
        
    except Exception as e:
        print(f"✗ API endpoint tests failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run all tests."""
    print("=" * 60)
    print("Hardware Monitoring Agent - Component Tests")
    print("=" * 60)
    
    results = {
        'ROCm Control': test_rocm_control(),
        'Metrics Collector': test_metrics_collector(),
        'Optimizer': test_optimizer(),
        'API Endpoints': test_api_endpoints()
    }
    
    print("\n" + "=" * 60)
    print("Test Results Summary")
    print("=" * 60)
    
    for test_name, passed in results.items():
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{test_name:.<40} {status}")
    
    all_passed = all(results.values())
    
    print("=" * 60)
    
    if all_passed:
        print("✓ All tests passed!")
        return 0
    else:
        print("✗ Some tests failed")
        return 1


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""
Coding Agent Executor - REST API for code execution
Provides HTTP endpoints for safe code execution
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from sandbox import Sandbox
import os
import logging
from datetime import datetime
from typing import Dict, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Initialize sandbox
sandbox = Sandbox()

# Stats tracking
stats = {
    "total_executions": 0,
    "successful_executions": 0,
    "failed_executions": 0,
    "safety_violations": 0,
    "start_time": datetime.now().isoformat()
}


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "coding-agent",
        "version": "1.0.0",
        "uptime_seconds": (datetime.now() - datetime.fromisoformat(stats["start_time"])).total_seconds()
    })


@app.route('/execute', methods=['POST'])
def execute_code():
    """Execute code in sandbox"""
    try:
        data = request.get_json()
        
        if not data or 'code' not in data:
            return jsonify({
                "success": False,
                "error": "Missing 'code' field in request"
            }), 400
        
        code = data['code']
        timeout = data.get('timeout', None)
        
        logger.info(f"Executing code (length: {len(code)} chars)")
        
        # Execute in sandbox
        success, output, result = sandbox.execute(code, timeout=timeout)
        
        # Update stats
        stats["total_executions"] += 1
        if success:
            stats["successful_executions"] += 1
        else:
            stats["failed_executions"] += 1
            if "Safety violation" in output:
                stats["safety_violations"] += 1
        
        # Return results
        response = {
            "success": success,
            "output": output,
            "result": str(result) if result is not None else None,
            "timestamp": datetime.now().isoformat()
        }
        
        logger.info(f"Execution {'succeeded' if success else 'failed'}")
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error in execute_code: {str(e)}", exc_info=True)
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/test', methods=['POST'])
def test_code():
    """Test code against test cases"""
    try:
        data = request.get_json()
        
        if not data or 'code' not in data or 'tests' not in data:
            return jsonify({
                "success": False,
                "error": "Missing 'code' or 'tests' field in request"
            }), 400
        
        code = data['code']
        test_cases = data['tests']
        
        logger.info(f"Testing code with {len(test_cases)} test cases")
        
        # Run tests
        results = sandbox.test_code(code, test_cases)
        
        # Update stats
        stats["total_executions"] += results["total"]
        stats["successful_executions"] += results["passed"]
        stats["failed_executions"] += results["failed"]
        
        logger.info(f"Tests completed: {results['passed']}/{results['total']} passed")
        
        return jsonify({
            "success": True,
            "results": results,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error in test_code: {str(e)}", exc_info=True)
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/stats', methods=['GET'])
def get_stats():
    """Get execution statistics"""
    return jsonify(stats)


@app.route('/config', methods=['GET'])
def get_config():
    """Get current sandbox configuration"""
    return jsonify({
        "max_execution_time": sandbox.max_execution_time,
        "max_memory_mb": sandbox.max_memory_mb,
        "allowed_imports": sandbox.allowed_imports,
        "allowed_builtins": sandbox.config.get("allowed_builtins", []),
        "blocked_modules": sandbox.config.get("blocked_modules", [])
    })


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        "success": False,
        "error": "Endpoint not found"
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        "success": False,
        "error": "Internal server error"
    }), 500


if __name__ == '__main__':
    port = int(os.getenv('PORT', '5000'))
    debug = os.getenv('DEBUG', 'false').lower() == 'true'
    
    logger.info(f"Starting Coding Agent on port {port}")
    logger.info(f"Max execution time: {sandbox.max_execution_time}s")
    logger.info(f"Max memory: {sandbox.max_memory_mb}MB")
    logger.info(f"Allowed imports: {sandbox.allowed_imports}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)

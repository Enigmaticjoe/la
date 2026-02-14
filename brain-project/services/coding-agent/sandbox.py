#!/usr/bin/env python3
"""
Coding Agent - Safe Code Execution Sandbox
Executes Python code in a restricted environment with safety checks
"""

import os
import sys
import io
import contextlib
import traceback
import yaml
from typing import Dict, Any, Optional, Tuple
from RestrictedPython import compile_restricted, safe_globals
from RestrictedPython.Guards import guarded_iter_unpack_sequence, guarded_unpack_sequence
import resource
import signal


class SafetyViolationError(Exception):
    """Raised when code violates safety rules"""
    pass


class Sandbox:
    """Safe code execution sandbox with resource limits"""
    
    def __init__(self, config_path: str = "safety-rules.yaml"):
        self.config = self._load_config(config_path)
        self.max_execution_time = int(os.getenv("MAX_EXECUTION_TIME", "300"))
        self.max_memory_mb = int(os.getenv("MAX_MEMORY_MB", "2048"))
        self.allowed_imports = self._parse_allowed_imports()
        
    def _load_config(self, path: str) -> Dict[str, Any]:
        """Load safety configuration"""
        try:
            with open(path, 'r') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"Warning: Could not load config from {path}: {e}")
            return self._default_config()
    
    def _default_config(self) -> Dict[str, Any]:
        """Default safety configuration"""
        return {
            "allowed_builtins": [
                "abs", "all", "any", "bin", "bool", "chr", "dict", "dir",
                "divmod", "enumerate", "filter", "float", "format", "hex",
                "int", "isinstance", "issubclass", "iter", "len", "list",
                "map", "max", "min", "oct", "ord", "pow", "range", "repr",
                "reversed", "round", "set", "slice", "sorted", "str", "sum",
                "tuple", "type", "zip"
            ],
            "blocked_modules": [
                "os", "sys", "subprocess", "socket", "urllib", "http",
                "ftplib", "smtplib", "pickle", "shelve", "importlib"
            ],
            "blocked_attributes": [
                "__import__", "exec", "eval", "compile", "open", "input",
                "raw_input", "__builtins__", "__globals__", "__locals__"
            ]
        }
    
    def _parse_allowed_imports(self) -> list:
        """Parse allowed imports from environment"""
        imports_str = os.getenv("ALLOWED_IMPORTS", "")
        if imports_str:
            return [imp.strip() for imp in imports_str.split(",")]
        return ["numpy", "pandas", "matplotlib", "math", "datetime", "json"]
    
    def _timeout_handler(self, signum, frame):
        """Handle execution timeout"""
        raise TimeoutError(f"Code execution exceeded {self.max_execution_time} seconds")
    
    def _check_imports(self, code: str) -> None:
        """Check if code contains only allowed imports"""
        blocked = self.config.get("blocked_modules", [])
        
        # Simple import detection (can be improved with AST parsing)
        lines = code.split('\n')
        for line in lines:
            line = line.strip()
            if line.startswith('import ') or line.startswith('from '):
                # Extract module name
                if line.startswith('import '):
                    module = line[7:].split()[0].split('.')[0]
                else:  # from X import Y
                    module = line.split()[1].split('.')[0]
                
                if module in blocked:
                    raise SafetyViolationError(
                        f"Import of blocked module '{module}' is not allowed"
                    )
                
                if module not in self.allowed_imports:
                    raise SafetyViolationError(
                        f"Import of '{module}' is not in allowed list: {self.allowed_imports}"
                    )
    
    def _create_safe_globals(self) -> Dict[str, Any]:
        """Create safe globals dictionary"""
        # Start with RestrictedPython safe globals
        safe_dict = safe_globals.copy()
        
        # Add allowed builtins
        allowed = self.config.get("allowed_builtins", [])
        for builtin in allowed:
            if hasattr(__builtins__, builtin):
                safe_dict[builtin] = getattr(__builtins__, builtin)
        
        # Add safe guards
        safe_dict['_iter_unpack_sequence_'] = guarded_iter_unpack_sequence
        safe_dict['_unpack_sequence_'] = guarded_unpack_sequence
        safe_dict['__builtins__'] = {k: safe_dict[k] for k in allowed}
        
        # Add allowed modules
        for module_name in self.allowed_imports:
            try:
                safe_dict[module_name] = __import__(module_name)
            except ImportError:
                pass  # Module not available, skip
        
        return safe_dict
    
    def execute(self, code: str, timeout: Optional[int] = None) -> Tuple[bool, str, Any]:
        """
        Execute code in sandbox
        
        Returns:
            Tuple of (success, output, result)
        """
        if timeout is None:
            timeout = self.max_execution_time
        
        try:
            # Safety checks
            self._check_imports(code)
            
            # Compile with restrictions
            byte_code = compile_restricted(
                code,
                filename='<sandbox>',
                mode='exec'
            )
            
            if byte_code.errors:
                return False, f"Compilation errors:\n{chr(10).join(byte_code.errors)}", None
            
            # Set resource limits
            try:
                # Set memory limit (soft, hard) in bytes
                memory_limit = self.max_memory_mb * 1024 * 1024
                resource.setrlimit(resource.RLIMIT_AS, (memory_limit, memory_limit))
            except:
                pass  # May fail in containers, that's okay
            
            # Set timeout
            signal.signal(signal.SIGALRM, self._timeout_handler)
            signal.alarm(timeout)
            
            # Capture stdout/stderr
            stdout_capture = io.StringIO()
            stderr_capture = io.StringIO()
            
            # Create safe execution environment
            safe_dict = self._create_safe_globals()
            safe_locals = {}
            
            # Execute
            with contextlib.redirect_stdout(stdout_capture), \
                 contextlib.redirect_stderr(stderr_capture):
                exec(byte_code.code, safe_dict, safe_locals)
            
            # Cancel timeout
            signal.alarm(0)
            
            # Get output
            stdout_val = stdout_capture.getvalue()
            stderr_val = stderr_capture.getvalue()
            
            output = ""
            if stdout_val:
                output += f"STDOUT:\n{stdout_val}\n"
            if stderr_val:
                output += f"STDERR:\n{stderr_val}\n"
            
            # Get result (last expression value or specific 'result' variable)
            result = safe_locals.get('result', None)
            
            return True, output or "Code executed successfully (no output)", result
            
        except TimeoutError as e:
            signal.alarm(0)
            return False, f"Timeout: {str(e)}", None
            
        except SafetyViolationError as e:
            signal.alarm(0)
            return False, f"Safety violation: {str(e)}", None
            
        except Exception as e:
            signal.alarm(0)
            error_trace = traceback.format_exc()
            return False, f"Execution error:\n{error_trace}", None
    
    def test_code(self, code: str, test_cases: list) -> Dict[str, Any]:
        """
        Test code against test cases
        
        Args:
            code: Code to test
            test_cases: List of test case dicts with 'input' and 'expected' keys
            
        Returns:
            Dictionary with test results
        """
        results = {
            "total": len(test_cases),
            "passed": 0,
            "failed": 0,
            "cases": []
        }
        
        for i, test in enumerate(test_cases):
            # Prepare test code
            test_code = code + f"\nresult = {test.get('input', 'None')}"
            
            # Execute
            success, output, result = self.execute(test_code)
            
            # Check result
            expected = test.get('expected')
            passed = success and result == expected
            
            if passed:
                results["passed"] += 1
            else:
                results["failed"] += 1
            
            results["cases"].append({
                "test_number": i + 1,
                "input": test.get('input'),
                "expected": expected,
                "actual": result,
                "passed": passed,
                "output": output
            })
        
        return results


if __name__ == "__main__":
    # Test the sandbox
    sandbox = Sandbox()
    
    # Test 1: Simple calculation
    code1 = """
result = sum(range(10))
print(f"Sum of 0-9: {result}")
"""
    success, output, result = sandbox.execute(code1)
    print(f"Test 1 - Success: {success}")
    print(f"Output: {output}")
    print(f"Result: {result}\n")
    
    # Test 2: Blocked import
    code2 = """
import os
result = os.system('ls')
"""
    success, output, result = sandbox.execute(code2)
    print(f"Test 2 - Success: {success}")
    print(f"Output: {output}\n")
    
    # Test 3: Allowed import (numpy)
    code3 = """
import numpy as np
result = np.array([1, 2, 3]).mean()
print(f"Mean: {result}")
"""
    success, output, result = sandbox.execute(code3)
    print(f"Test 3 - Success: {success}")
    print(f"Output: {output}")
    print(f"Result: {result}\n")

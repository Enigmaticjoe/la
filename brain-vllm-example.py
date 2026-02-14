#!/usr/bin/env python3
"""
Brain vLLM Model Loading Example
AMD RX 7900 XT (20GB VRAM) | 128GB RAM | ROCm

This example demonstrates how to load and use AWQ-quantized models
with vLLM optimized for AMD GPU hardware.

Usage:
    python3 brain-vllm-example.py
"""

import requests
import json
import time
from typing import Dict, List, Optional

# Configuration
VLLM_API_BASE = "http://localhost:8000/v1"
MODEL_NAME = "cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ"

class BrainVLLMClient:
    """Client for interacting with Brain vLLM server on AMD GPU"""
    
    def __init__(self, base_url: str = VLLM_API_BASE):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({"Content-Type": "application/json"})
    
    def check_health(self) -> bool:
        """Check if vLLM server is healthy"""
        try:
            response = self.session.get(f"{self.base_url}/models")
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def list_models(self) -> List[str]:
        """List available models"""
        response = self.session.get(f"{self.base_url}/models")
        response.raise_for_status()
        data = response.json()
        return [model['id'] for model in data.get('data', [])]
    
    def generate_completion(
        self,
        prompt: str,
        max_tokens: int = 512,
        temperature: float = 0.7,
        top_p: float = 0.9,
        **kwargs
    ) -> str:
        """Generate text completion"""
        payload = {
            "model": MODEL_NAME,
            "prompt": prompt,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "top_p": top_p,
            **kwargs
        }
        
        response = self.session.post(
            f"{self.base_url}/completions",
            json=payload
        )
        response.raise_for_status()
        
        data = response.json()
        return data['choices'][0]['text']
    
    def chat_completion(
        self,
        messages: List[Dict[str, str]],
        max_tokens: int = 512,
        temperature: float = 0.7,
        **kwargs
    ) -> str:
        """Generate chat completion"""
        payload = {
            "model": MODEL_NAME,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
            **kwargs
        }
        
        response = self.session.post(
            f"{self.base_url}/chat/completions",
            json=payload
        )
        response.raise_for_status()
        
        data = response.json()
        return data['choices'][0]['message']['content']
    
    def stream_completion(
        self,
        prompt: str,
        max_tokens: int = 512,
        temperature: float = 0.7,
        **kwargs
    ):
        """Stream text completion token by token"""
        payload = {
            "model": MODEL_NAME,
            "prompt": prompt,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "stream": True,
            **kwargs
        }
        
        response = self.session.post(
            f"{self.base_url}/completions",
            json=payload,
            stream=True
        )
        response.raise_for_status()
        
        for line in response.iter_lines():
            if line:
                line = line.decode('utf-8')
                if line.startswith('data: '):
                    data_str = line[6:]  # Remove 'data: ' prefix
                    if data_str.strip() == '[DONE]':
                        break
                    try:
                        data = json.loads(data_str)
                        if 'choices' in data and len(data['choices']) > 0:
                            delta = data['choices'][0].get('text', '')
                            if delta:
                                yield delta
                    except json.JSONDecodeError:
                        continue


def main():
    """Main example demonstrating vLLM usage on AMD GPU"""
    
    print("=" * 70)
    print("Brain vLLM Client - AMD RX 7900 XT Optimized")
    print("=" * 70)
    print()
    
    # Initialize client
    client = BrainVLLMClient()
    
    # Check server health
    print("🔍 Checking vLLM server health...")
    if not client.check_health():
        print("❌ vLLM server is not responding!")
        print("   Make sure brain-stack.yml is deployed:")
        print("   docker compose -f brain-stack.yml up -d")
        return
    print("✅ vLLM server is healthy")
    print()
    
    # List available models
    print("📋 Available models:")
    models = client.list_models()
    for model in models:
        print(f"   • {model}")
    print()
    
    # Example 1: Simple completion
    print("=" * 70)
    print("Example 1: Simple Text Completion")
    print("=" * 70)
    prompt = "Explain quantum computing in simple terms:"
    print(f"Prompt: {prompt}")
    print()
    
    start_time = time.time()
    response = client.generate_completion(
        prompt=prompt,
        max_tokens=150,
        temperature=0.7
    )
    elapsed = time.time() - start_time
    
    print(f"Response: {response}")
    print()
    print(f"⏱️  Generated in {elapsed:.2f}s")
    print()
    
    # Example 2: Chat completion
    print("=" * 70)
    print("Example 2: Chat Completion")
    print("=" * 70)
    messages = [
        {"role": "system", "content": "You are a helpful AI assistant specialized in technology."},
        {"role": "user", "content": "What are the advantages of AWQ quantization for LLMs?"}
    ]
    print(f"Messages: {json.dumps(messages, indent=2)}")
    print()
    
    start_time = time.time()
    response = client.chat_completion(
        messages=messages,
        max_tokens=200,
        temperature=0.7
    )
    elapsed = time.time() - start_time
    
    print(f"Assistant: {response}")
    print()
    print(f"⏱️  Generated in {elapsed:.2f}s")
    print()
    
    # Example 3: Streaming completion
    print("=" * 70)
    print("Example 3: Streaming Text Completion")
    print("=" * 70)
    prompt = "Write a haiku about artificial intelligence:"
    print(f"Prompt: {prompt}")
    print()
    print("Response (streaming): ", end='', flush=True)
    
    start_time = time.time()
    token_count = 0
    for token in client.stream_completion(
        prompt=prompt,
        max_tokens=100,
        temperature=0.8
    ):
        print(token, end='', flush=True)
        token_count += 1
    elapsed = time.time() - start_time
    
    print()
    print()
    print(f"⏱️  Streamed {token_count} tokens in {elapsed:.2f}s")
    print(f"📊 Throughput: ~{token_count/elapsed:.1f} tokens/second")
    print()
    
    # AMD GPU Performance Notes
    print("=" * 70)
    print("AMD RX 7900 XT Performance Notes")
    print("=" * 70)
    print("• Model: Dolphin 2.9.3 Llama 3.1 8B AWQ (4-bit quantized)")
    print("• VRAM Usage: ~8-9GB / 20GB available (~45%)")
    print("• Expected Throughput: 30-50 tokens/second")
    print("• Context Length: 16K tokens (configurable)")
    print("• Concurrent Requests: 16 (configurable)")
    print("• ROCm Backend: Optimized for gfx1100 architecture")
    print()
    print("To monitor GPU usage:")
    print("  rocm-smi --showmeminfo vram --showuse")
    print()
    print("To adjust settings, edit brain-stack.yml:")
    print("  --gpu-memory-utilization (default: 0.90)")
    print("  --max-model-len (default: 16384)")
    print("  --max-num-seqs (default: 16)")
    print("=" * 70)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Interrupted by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()

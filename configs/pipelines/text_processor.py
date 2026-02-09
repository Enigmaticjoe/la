"""
title: Text Processing Pipeline
description: Advanced text processing and transformation
author: Open WebUI
version: 1.0.0
"""

from typing import List, Dict, Any
import re


class Pipeline:
    def __init__(self):
        self.name = "Text Processor"
        self.description = "Processes and transforms text messages"
    
    def process(self, messages: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Process messages through the pipeline.
        
        Args:
            messages: List of message dictionaries
            
        Returns:
            Processed messages
        """
        processed_messages = []
        
        for message in messages:
            if message.get('role') == 'user':
                content = message.get('content', '')
                
                # Extract and store metadata
                metadata = message.get('metadata', {})
                
                # Extract URLs
                urls = self._extract_urls(content)
                if urls:
                    metadata['urls'] = urls
                
                # Extract code blocks
                code_blocks = self._extract_code(content)
                if code_blocks:
                    metadata['code_blocks'] = code_blocks
                
                # Clean text
                content = self._clean_text(content)
                
                # Update message
                message['content'] = content
                if metadata:
                    message['metadata'] = metadata
            
            processed_messages.append(message)
        
        return processed_messages
    
    def _clean_text(self, text: str) -> str:
        """Remove excessive whitespace and normalize text."""
        # Remove multiple spaces
        text = re.sub(r'\s+', ' ', text)
        # Remove multiple newlines
        text = re.sub(r'\n{3,}', '\n\n', text)
        return text.strip()
    
    def _extract_urls(self, text: str) -> List[str]:
        """Extract URLs from text."""
        url_pattern = r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'
        return re.findall(url_pattern, text)
    
    def _extract_code(self, text: str) -> List[Dict[str, str]]:
        """Extract code blocks from text."""
        code_pattern = r'```(\w+)?\n(.*?)```'
        matches = re.findall(code_pattern, text, re.DOTALL)
        return [
            {'language': lang or 'text', 'code': code.strip()}
            for lang, code in matches
        ]

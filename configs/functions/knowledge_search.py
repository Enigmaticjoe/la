"""
title: Knowledge Search Function
description: Search through the knowledge base using ChromaDB
author: Open WebUI
version: 1.0.0
"""

from typing import List, Dict, Optional
import requests


class Tools:
    def __init__(self):
        self.chroma_url = "http://chromadb:8000"
    
    def search_knowledge(
        self,
        query: str,
        collection: str = "documents",
        top_k: int = 5
    ) -> List[Dict]:
        """
        Search the knowledge base for relevant documents.
        
        Args:
            query: Search query text
            collection: Collection name to search in
            top_k: Number of results to return
            
        Returns:
            List of relevant documents with metadata
        """
        try:
            # Query ChromaDB
            url = f"{self.chroma_url}/api/v1/collections/{collection}/query"
            
            payload = {
                "query_texts": [query],
                "n_results": top_k
            }
            
            response = requests.post(url, json=payload, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            # Format results
            results = []
            if data.get('documents') and len(data['documents']) > 0:
                for i, doc in enumerate(data['documents'][0]):
                    result = {
                        'content': doc,
                        'metadata': data.get('metadatas', [[]])[0][i] if data.get('metadatas') else {},
                        'distance': data.get('distances', [[]])[0][i] if data.get('distances') else None
                    }
                    results.append(result)
            
            return results
            
        except requests.RequestException as e:
            return [{"error": f"ChromaDB request error: {str(e)}"}]
        except Exception as e:
            return [{"error": f"Search error: {str(e)}"}]
    
    def list_collections(self) -> List[str]:
        """
        List all available knowledge base collections.
        
        Returns:
            List of collection names
        """
        try:
            url = f"{self.chroma_url}/api/v1/collections"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            
            collections = response.json()
            return [c['name'] for c in collections]
            
        except Exception as e:
            return [f"Error listing collections: {str(e)}"]

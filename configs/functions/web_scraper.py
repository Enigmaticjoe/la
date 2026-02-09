"""
title: Web Scraper Function
description: Scrapes web pages and extracts content
author: Open WebUI
version: 1.0.0
"""

from typing import Optional
import requests
from bs4 import BeautifulSoup


class Tools:
    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
    
    def scrape_url(
        self, 
        url: str, 
        selector: Optional[str] = None,
        timeout: int = 10
    ) -> str:
        """
        Scrapes a URL and returns the content.
        
        Args:
            url: The URL to scrape
            selector: CSS selector to extract specific content (optional)
            timeout: Request timeout in seconds
            
        Returns:
            Scraped content as text
        """
        try:
            response = requests.get(url, headers=self.headers, timeout=timeout)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Remove unwanted elements
            for element in soup(['script', 'style', 'nav', 'footer', 'header']):
                element.decompose()
            
            if selector:
                # Extract specific elements
                elements = soup.select(selector)
                if not elements:
                    return f"No elements found with selector: {selector}"
                content = '\n\n'.join([el.get_text(strip=True) for el in elements])
            else:
                # Get all text content
                content = soup.get_text(separator='\n', strip=True)
            
            # Clean up multiple newlines
            content = '\n'.join([line for line in content.split('\n') if line.strip()])
            
            return content
            
        except requests.RequestException as e:
            return f"Error scraping {url}: {str(e)}"
        except Exception as e:
            return f"Unexpected error: {str(e)}"

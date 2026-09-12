#!/usr/bin/env python3
"""
Jio.com Web Scraper & Crawler
Extracts live text, headings, plans, FAQs, and product info from https://www.jio.com/
"""

import urllib.request
import urllib.parse
import gzip
import re
import json
import os
import sys
from bs4 import BeautifulSoup

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate'
}

TARGET_PAGES = [
    {
        "url": "https://www.jio.com/",
        "category": "Home & Overview",
        "title": "Jio Official Portal - Mobile, Fiber, 5G & Digital Services"
    },
    {
        "url": "https://www.jio.com/5g/",
        "category": "True 5G",
        "title": "Jio True 5G - Standalone 5G Network & Welcome Offer"
    },
    {
        "url": "https://www.jio.com/fiber/",
        "category": "JioFiber Broadband",
        "title": "JioFiber - High Speed Home Fiber Broadband & 4K Set Top Box"
    },
    {
        "url": "https://www.jio.com/help/home",
        "category": "Customer Support & FAQs",
        "title": "Jio Customer Support, Help Center & Helplines"
    },
    {
        "url": "https://www.jio.com/help/contact-us",
        "category": "Customer Support & FAQs",
        "title": "Jio Contact Us - Helpline Numbers & Support Email"
    }
]


def fetch_url(url, timeout=12):
    """Fetch URL with automatic gzip decompression."""
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            raw = res.read()
            if res.headers.get('Content-Encoding') == 'gzip':
                return gzip.decompress(raw).decode('utf-8', errors='ignore')
            return raw.decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"[SCRAPER] Warning: Could not fetch {url}: {e}")
        return None


def extract_clean_text(html):
    """Extract clean textual content and structural chunks from HTML."""
    if not html:
        return []

    soup = BeautifulSoup(html, 'html.parser')

    # Remove script, style, noscript, svg elements
    for el in soup(['script', 'style', 'noscript', 'svg', 'iframe']):
        el.decompose()

    chunks = []

    # Extract headings + paragraphs pairs
    for section in soup.find_all(['section', 'article', 'div'], class_=re.compile(r'plan|banner|feature|faq|card|about|content', re.I)):
        text = section.get_text(separator=' ', strip=True)
        text = re.sub(r'\s+', ' ', text)
        if len(text) > 100 and len(text) < 3000:
            chunks.append(text)

    # General paragraphs
    body_text = soup.body.get_text(separator='\n', strip=True) if soup.body else ''
    lines = [re.sub(r'\s+', ' ', l).strip() for l in body_text.split('\n') if len(l.strip()) > 50]
    
    return list(set(chunks + lines))


def crawl_jio_site():
    """Scrape configured Jio pages and return extracted documents."""
    scraped_docs = []
    print("[SCRAPER] Starting crawl of https://www.jio.com/ pages...")

    for target in TARGET_PAGES:
        url = target["url"]
        print(f"[SCRAPER] Fetching: {url} ...")
        html = fetch_url(url)
        if html:
            paragraphs = extract_clean_text(html)
            print(f"[SCRAPER] Extracted {len(paragraphs)} text fragments from {url}")
            
            # Group fragments into coherent documents
            combined_text = " ".join(paragraphs[:15])
            if combined_text:
                scraped_docs.append({
                    "id": "live_" + re.sub(r'[^a-zA-Z0-9]', '_', url),
                    "url": url,
                    "title": target["title"],
                    "category": target["category"],
                    "content": combined_text[:4000],
                    "keywords": [w.lower() for w in target["title"].split() if len(w) > 3]
                })

    print(f"[SCRAPER] Completed live crawl. Gathered {len(scraped_docs)} documents.")
    return scraped_docs


if __name__ == '__main__':
    if '--test' in sys.argv:
        print("[TEST] Testing scraper on homepage...")
        html = fetch_url("https://www.jio.com/")
        assert html is not None and len(html) > 10000, "Failed to scrape homepage"
        print(f"[TEST] Successfully scraped homepage ({len(html)} bytes).")
        sys.exit(0)

    docs = crawl_jio_site()
    print(f"Scraped {len(docs)} documents.")

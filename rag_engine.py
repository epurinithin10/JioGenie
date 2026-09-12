#!/usr/bin/env python3
"""
JioGenie RAG Engine (Retrieval-Augmented Generation)
Combines Okapi BM25 semantic retrieval with Groq LPU LLMs
to answer any question grounded in https://www.jio.com/ data.
"""

import json
import os
import re
import math
import urllib.request
import urllib.parse
from collections import Counter

KB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "jio_knowledge.json")
GROQ_DEFAULT_KEY = os.environ.get("GROQ_API_KEY", "")

STOP_WORDS = {
    "a", "about", "above", "after", "again", "against", "all", "am", "an", "and",
    "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being",
    "below", "between", "both", "but", "by", "can", "can't", "cannot", "could",
    "did", "do", "does", "doing", "don't", "down", "during", "each", "few", "for",
    "from", "further", "had", "has", "have", "having", "he", "her", "here", "hers",
    "herself", "him", "himself", "his", "how", "i", "if", "in", "into", "is",
    "isn't", "it", "its", "itself", "let's", "me", "more", "most", "my", "myself",
    "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought",
    "our", "ours", "ourselves", "out", "over", "own", "same", "she", "should",
    "so", "some", "such", "than", "that", "the", "their", "theirs", "them",
    "themselves", "then", "there", "these", "they", "this", "those", "through",
    "to", "too", "under", "until", "up", "very", "was", "we", "were", "what",
    "when", "where", "which", "while", "who", "whom", "why", "with", "would",
    "you", "your", "yours", "yourself", "yourselves", "please", "tell", "give"
}

SYNONYMS = {
    "recharge": ["prepaid", "plan", "pack", "validity", "tariff", "data"],
    "broadband": ["jiofiber", "airfiber", "wifi", "router", "fiber"],
    "wifi": ["broadband", "jiofiber", "airfiber", "router"],
    "sim": ["esim", "port", "mnp", "activation"],
    "port": ["mnp", "switch", "transfer", "upc"],
    "unlimited": ["true 5g", "welcome offer", "data"],
    "care": ["customer", "helpline", "complaint", "number", "support", "198", "199"],
    "hotline": ["customer", "helpline", "complaint", "198", "199"],
    "ott": ["netflix", "prime", "hotstar", "jiocinema", "sonyliv", "zee5"],
    "roaming": ["international", "flight", "abroad", "usa", "uae"]
}


def tokenize(text):
    """Normalize and tokenize text into words and numbers."""
    if not text:
        return []
    cleaned = re.sub(r'[^a-zA-Z0-9\s₹]', ' ', str(text).lower())
    tokens = cleaned.split()
    return [t for t in tokens if t not in STOP_WORDS and len(t) > 1]


class JioRAG:
    def __init__(self, kb_file=KB_PATH, k1=1.5, b=0.75):
        self.kb_file = kb_file
        self.k1 = k1
        self.b = b
        self.documents = []
        self.doc_tokens = []
        self.doc_lengths = []
        self.avg_doc_len = 0
        self.doc_freqs = Counter()
        self.idf = {}
        self.load_and_index()

    def load_and_index(self):
        """Load knowledge documents and build inverted BM25 index."""
        if not os.path.exists(self.kb_file):
            print(f"[RAG] Warning: {self.kb_file} not found.")
            return

        with open(self.kb_file, "r", encoding="utf-8") as f:
            self.documents = json.load(f)

        self.doc_tokens = []
        self.doc_lengths = []
        self.doc_freqs = Counter()

        for doc in self.documents:
            # Combine title, keywords, category, and content with weights
            weighted_text = (
                f"{doc.get('title', '')} {doc.get('title', '')} "
                f"{' '.join(doc.get('keywords', []))} {' '.join(doc.get('keywords', []))} "
                f"{doc.get('category', '')} "
                f"{doc.get('content', '')}"
            )
            tokens = tokenize(weighted_text)
            self.doc_tokens.append(tokens)
            self.doc_lengths.append(len(tokens))

            # Track document frequency for each unique term
            unique_terms = set(tokens)
            for t in unique_terms:
                self.doc_freqs[t] += 1

        total_docs = len(self.documents)
        self.avg_doc_len = sum(self.doc_lengths) / max(total_docs, 1)

        # Compute IDF for every observed vocabulary term
        self.idf = {}
        for term, df in self.doc_freqs.items():
            # BM25 probabilistic IDF
            self.idf[term] = math.log((total_docs - df + 0.5) / (df + 0.5) + 1.0)

        print(f"[RAG] Successfully indexed {total_docs} Jio documents. Avg length: {self.avg_doc_len:.1f} tokens.")

    def expand_query(self, query):
        """Expand user query with domain-specific telecom synonyms."""
        base_tokens = tokenize(query)
        expanded = list(base_tokens)

        for token in base_tokens:
            if token in SYNONYMS:
                for syn in SYNONYMS[token]:
                    expanded.append(syn)

        return expanded

    def retrieve(self, query, top_k=4):
        """Score documents against query using BM25 with numeric & phrase boosts."""
        if not self.documents:
            return []

        expanded_tokens = self.expand_query(query)
        query_terms = Counter(expanded_tokens)
        raw_query_lower = query.lower()

        # Extract specific numeric tokens (e.g. 349, 859, 3599, 84, 28, 599)
        numeric_terms = re.findall(r'\b\d+\b', raw_query_lower)

        scores = []

        for idx, (doc, doc_toks, doc_len) in enumerate(zip(self.documents, self.doc_tokens, self.doc_lengths)):
            score = 0.0
            doc_term_counts = Counter(doc_toks)

            # Okapi BM25 Calculation
            for term, q_freq in query_terms.items():
                if term not in doc_term_counts:
                    continue

                tf = doc_term_counts[term]
                idf = self.idf.get(term, 0.1)

                numerator = tf * (self.k1 + 1.0)
                denominator = tf + self.k1 * (1.0 - self.b + self.b * (doc_len / self.avg_doc_len))
                score += idf * (numerator / denominator) * q_freq

            # Exact phrase / numeric bonus
            doc_content_lower = (doc.get('title', '') + ' ' + doc.get('content', '')).lower()

            for num in numeric_terms:
                if num in doc_content_lower:
                    score += 4.5  # Strong boost for matching exact plan amounts or days

            # Category boost
            if doc.get('category', '').lower() in raw_query_lower:
                score += 3.0

            scores.append((score, doc))

        # Sort by relevance score descending
        scores.sort(key=lambda x: x[0], reverse=True)

        results = []
        for score, doc in scores[:top_k]:
            if score > 0:
                results.append({
                    "score": round(score, 3),
                    "id": doc.get("id"),
                    "title": doc.get("title"),
                    "category": doc.get("category"),
                    "url": doc.get("url"),
                    "content": doc.get("content")
                })

        return results

    def build_rag_prompt(self, query, retrieved_chunks):
        """Construct a grounded prompt combining retrieved context with user query."""
        context_blocks = []
        citations = []

        for i, chunk in enumerate(retrieved_chunks, 1):
            context_blocks.append(
                f"[Document {i}] Title: {chunk['title']}\n"
                f"Category: {chunk['category']}\n"
                f"Source URL: {chunk['url']}\n"
                f"Content: {chunk['content']}\n"
            )
            citations.append({
                "title": chunk["title"],
                "url": chunk["url"],
                "category": chunk["category"]
            })

        context_str = "\n".join(context_blocks)

        system_instruction = (
            "You are JioGenie, the official expert AI assistant for Reliance Jio (https://www.jio.com/). "
            "You have access to verified, up-to-date knowledge from jio.com provided in the context below.\n"
            "Guidelines:\n"
            "1. Answer the user's question thoroughly, accurately, and politely using the provided context.\n"
            "2. State exact plan costs (e.g. ₹349, ₹859, ₹3599), data quotas (e.g. 2 GB/day), validity days, and features.\n"
            "3. Cite official URLs from the context in markdown links, e.g. [Jio True 5G](https://www.jio.com/5g).\n"
            "4. Format your response cleanly using Markdown, with bolding, bullet points, and tables where applicable.\n"
            "5. If a specific detail is not covered in the context, politely state what you know and refer the user to www.jio.com or MyJio."
        )

        user_content = (
            f"=== VERIFIED JIO.COM CONTEXT ===\n{context_str}\n\n"
            f"=== USER QUESTION ===\n{query}\n\n"
            "Provide an authoritative, detailed, and cited answer based on the verified context above."
        )

        return system_instruction, user_content, citations

    def query_rag(self, query, model="openai/gpt-oss-120b", api_key=None, stream=False):
        """Complete RAG pipeline: Retrieve -> Augment -> Generate via Groq."""
        key = api_key or os.environ.get("GROQ_API_KEY", GROQ_DEFAULT_KEY)
        retrieved = self.retrieve(query, top_k=4)

        if not retrieved:
            # Fallback if no specific documents scored
            retrieved = self.documents[:2]

        system_prompt, user_content, citations = self.build_rag_prompt(query, retrieved)

        payload = {
            "model": model or "openai/gpt-oss-120b",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content}
            ],
            "temperature": 0.4,
            "stream": stream
        }

        req = urllib.request.Request(
            "https://api.groq.com/openai/v1/chat/completions",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
            }
        )

        if stream:
            return urllib.request.urlopen(req, timeout=30), citations

        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            answer = data["choices"][0]["message"]["content"]
            return {
                "answer": answer,
                "citations": citations,
                "retrieved_chunks": retrieved
            }


if __name__ == "__main__":
    import sys
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    rag = JioRAG()
    test_queries = [
        "What is the best 84-day Jio plan with Unlimited 5G?",
        "How do I convert my physical SIM to Jio eSIM on iPhone?",
        "Compare JioFiber and JioAirFiber"
    ]

    print("\n" + "=" * 60)
    print("Testing Jio BM25 Retrieval Engine")
    print("=" * 60)

    for q in test_queries:
        print(f"\nQuery: '{q}'")
        chunks = rag.retrieve(q, top_k=2)
        for i, c in enumerate(chunks, 1):
            print(f"  [{i}] (Score: {c['score']}) {c['title']} -> {c['url']}")

    if "--live" in sys.argv:
        print("\n" + "=" * 60)
        print("Testing Live RAG Groq Synthesis...")
        print("=" * 60)
        res = rag.query_rag("What is the best 84-day Jio plan with Unlimited 5G?")
        print(res["answer"])
        print("\nCitations:", [c["url"] for c in res["citations"]])

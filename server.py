#!/usr/bin/env python3
"""
JioGenie Local HTTP Server & RAG Gateway
Serves frontend, proxies Groq API, and provides RAG endpoints for https://www.jio.com/
"""

import http.server
import socketserver
import json
import os
import sys
import webbrowser
import threading
import time
import urllib.request
import urllib.parse
import mimetypes

if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

mimetypes.add_type('text/javascript', '.jsx')
mimetypes.add_type('application/javascript', '.js')

from rag_engine import JioRAG
try:
    from scraper import crawl_jio_site
except Exception:
    def crawl_jio_site():
        return []

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))
FLUTTER_DIR = os.path.join(DIRECTORY, "flutter_app", "build", "web")

# Load .env file if present
_env_path = os.path.join(DIRECTORY, ".env")
if os.path.exists(_env_path):
    try:
        with open(_env_path, "r", encoding="utf-8") as _f:
            for _line in _f:
                _line = _line.strip()
                if _line and not _line.startswith("#") and "=" in _line:
                    _k, _v = _line.split("=", 1)
                    os.environ.setdefault(_k.strip(), _v.strip().strip('"').strip("'"))
    except Exception:
        pass

# Global RAG Instance
rag_engine = JioRAG()


class JioGenieHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        use_react = '--react' in sys.argv
        serve_dir = DIRECTORY if use_react else (FLUTTER_DIR if os.path.exists(FLUTTER_DIR) else DIRECTORY)
        super().__init__(*args, directory=serve_dir, **kwargs)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def do_GET(self):
        # API Config Endpoint
        if self.path == '/api/config':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            cfg = {"groq_key": os.environ.get("GROQ_API_KEY", "")}
            self.wfile.write(json.dumps(cfg).encode('utf-8'))
            return

        # API Health Endpoint
        if self.path == '/api/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            payload = {
                "status": "ok",
                "app": "JioGenie - Unofficial AI Assistance for Jio",
                "version": "2.3.0",
                "rag_documents": len(rag_engine.documents),
                "engine": "Groq LPU + Jio.com RAG",
                "python": sys.version
            }
            self.wfile.write(json.dumps(payload).encode('utf-8'))
            return

        # Default static file handler
        return super().do_GET()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8') if content_length > 0 else '{}'
        
        try:
            data = json.loads(body)
        except Exception:
            data = {}

        # 1. RAG Search Query (Inspection & Citations)
        if self.path == '/api/rag/search':
            query = data.get('query', '')
            results = rag_engine.retrieve(query, top_k=5)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({"query": query, "results": results}).encode('utf-8'))
            return

        # 2. RAG Chat Endpoint (Streaming or Full Response)
        if self.path == '/api/rag/chat':
            query = data.get('query') or data.get('prompt', '')
            model = data.get('model', 'openai/gpt-oss-120b')
            want_stream = data.get('stream', True)

            if not query:
                self.send_error(400, "Missing query")
                return

            try:
                if not want_stream:
                    result = rag_engine.query_rag(query, model=model)
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    self.wfile.write(json.dumps(result).encode('utf-8'))
                    return

                # Streaming SSE
                groq_stream, citations = rag_engine.query_rag(query, model=model, stream=True)
                self.send_response(200)
                self.send_header('Content-Type', 'text/event-stream')
                self.send_header('Cache-Control', 'no-cache')
                self.send_header('Connection', 'close')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()

                # Send initial citations metadata packet
                init_meta = {"type": "metadata", "citations": citations}
                self.wfile.write(f"data: {json.dumps(init_meta)}\n\n".encode('utf-8'))
                self.wfile.flush()

                sent_done = False
                try:
                    for line in groq_stream:
                        self.wfile.write(line)
                        self.wfile.flush()
                        if b"[DONE]" in line:
                            sent_done = True
                except (BrokenPipeError, ConnectionResetError):
                    pass
                finally:
                    if hasattr(groq_stream, 'close'):
                        try:
                            groq_stream.close()
                        except Exception:
                            pass

                if not sent_done:
                    try:
                        self.wfile.write(b"data: [DONE]\n\n")
                        self.wfile.flush()
                    except Exception:
                        pass

                self.close_connection = True
                return

            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode('utf-8'))
                return

        # 3. Live Crawl / Refresh Knowledge Base Endpoint
        if self.path == '/api/rag/crawl':
            new_docs = crawl_jio_site()
            if new_docs:
                rag_engine.documents.extend(new_docs)
                rag_engine.load_and_index()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "success",
                "scraped_count": len(new_docs),
                "total_documents": len(rag_engine.documents)
            }).encode('utf-8'))
            return

        # 4. Standard Groq API Proxy Endpoint
        if self.path in ('/api/chat', '/api/groq'):
            auth_header = self.headers.get('Authorization', '')
            if auth_header.startswith('Bearer '):
                groq_key = auth_header.split('Bearer ', 1)[1].strip()
            else:
                groq_key = os.environ.get('GROQ_API_KEY', GROQ_DEFAULT_KEY)

            req_headers = {
                'Authorization': f'Bearer {groq_key}',
                'Content-Type': 'application/json',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
            }

            groq_req = urllib.request.Request(
                'https://api.groq.com/openai/v1/chat/completions',
                data=json.dumps(data).encode('utf-8'),
                headers=req_headers
            )

            try:
                with urllib.request.urlopen(groq_req, timeout=45) as resp:
                    resp_data = resp.read()
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    self.wfile.write(resp_data)
            except urllib.error.HTTPError as e:
                err_data = e.read()
                self.send_response(e.code)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(err_data)
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode('utf-8'))
            return

        self.send_error(404, "Endpoint not found")

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()


def run_test(port=8001):
    """Smoke test to verify RAG health and query resolution."""
    print(f"[TEST] Starting background server on port {port}...")
    server = socketserver.TCPServer(("", port), JioGenieHandler)
    server_thread = threading.Thread(target=server.serve_forever, daemon=True)
    server_thread.start()

    time.sleep(0.5)

    try:
        # Test 1: Health check
        test_url = f"http://localhost:{port}/api/health"
        print(f"[TEST] Sending GET request to {test_url}...")
        with urllib.request.urlopen(urllib.request.Request(test_url), timeout=4) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            print(f"[TEST] Health status: {data}")
            assert data.get("status") == "ok"
            assert data.get("rag_documents", 0) > 0

        # Test 2: RAG Search test
        search_url = f"http://localhost:{port}/api/rag/search"
        print(f"[TEST] Sending POST to {search_url}...")
        req = urllib.request.Request(
            search_url,
            data=json.dumps({"query": "JioAirFiber installation"}).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            res = json.loads(resp.read().decode('utf-8'))
            print(f"[TEST] RAG Search returned {len(res.get('results', []))} results. Top result: {res['results'][0]['title']}")
            assert len(res.get("results", [])) > 0

        print("[TEST] SUCCESS! All server & RAG tests passed.")
    finally:
        print("[TEST] Shutting down test server...")
        server.shutdown()
        server.server_close()
    return 0


def main():
    port = PORT
    if len(sys.argv) > 1:
        if sys.argv[1] == '--test':
            sys.exit(run_test(8001))
        elif sys.argv[1] == '--port' and len(sys.argv) > 2:
            port = int(sys.argv[2])

    candidate_ports = [port, 8080, 8050, 8081, 8088, 8888]
    httpd = None
    actual_port = None
    socketserver.TCPServer.allow_reuse_address = True

    for p in candidate_ports:
        try:
            httpd = socketserver.TCPServer(("", p), JioGenieHandler)
            actual_port = p
            break
        except OSError:
            continue

    if not httpd:
        print(f"[ERROR] Could not bind to any candidate port {candidate_ports}")
        sys.exit(1)

    print("=" * 65)
    print(">> JioGenie - Unofficial AI Assistance for Jio is running at:")
    print(f"   Local URL:  http://localhost:{actual_port}")
    use_react = '--react' in sys.argv
    frontend_name = 'React App' if use_react else ('Flutter Web App' if os.path.exists(FLUTTER_DIR) else 'React App')
    print(f"   Frontend:   {frontend_name}")
    print(f"   RAG KB:     {len(rag_engine.documents)} verified Jio.com documents indexed")
    print("   Engine:     Groq Cloud LPU + Okapi BM25 RAG")
    print("=" * 65)
    print("Press Ctrl + C to stop the server.")

    if '--no-browser' not in sys.argv:
        threading.Timer(0.8, lambda: webbrowser.open(f"http://localhost:{actual_port}")).start()

    with httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down JioGenie server.")


if __name__ == '__main__':
    main()

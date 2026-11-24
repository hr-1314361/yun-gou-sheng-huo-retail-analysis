# -*- coding: utf-8 -*-
"""
第4周 子任务2：大屏数据接口（零依赖，Python 标准库）
=====================================================
作用：为大屏提供后端 JSON 接口，演示「前端读取接口」的数据链路。
接口：
    GET /api/health      -> {"status": "ok"}
    GET /api/dashboard   -> 大屏全量数据（与 data/dashboard_data.json 一致）
    GET /                -> 静态页面（index.html 等）

启动：
    python api_server.py            # http://127.0.0.1:8000/index.html
    python api_server.py 9000       # 指定端口

接口模式预览：
    http://127.0.0.1:8000/index.html?api=1

生产环境可将 build_payload() 改为查询 Hive（ydsh_ads 层）后实时组装，
前端 main.js 无需修改。
"""
import json
import os
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(BASE_DIR, "data", "dashboard_data.json")


def build_payload() -> dict:
    """读取数据文件；生产环境替换为 Hive 查询结果组装"""
    with open(DATA_FILE, encoding="utf-8") as f:
        return json.load(f)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    def _send_json(self, obj, status=200):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/api/health":
            self._send_json({"status": "ok", "service": "dashboard-api"})
            return
        if path == "/api/dashboard":
            try:
                self._send_json(build_payload())
            except Exception as e:
                self._send_json({"error": str(e)}, status=500)
            return
        super().do_GET()

    def log_message(self, fmt, *args):
        sys.stdout.write("[API] %s\n" % (fmt % args))


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print("=" * 56)
    print(f"大屏服务已启动：http://127.0.0.1:{port}/index.html")
    print(f"接口模式预览：http://127.0.0.1:{port}/index.html?api=1")
    print(f"数据接口：http://127.0.0.1:{port}/api/dashboard")
    print("=" * 56)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.shutdown()


if __name__ == "__main__":
    main()

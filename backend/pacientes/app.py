import json
import os
from typing import Tuple, Any, Dict

# ---------- Helpers comunes (sin dependencias externas) ----------
CORS = {
    "Access-Control-Allow-Origin": "*",            
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
}

def _resp(body: Any, status: int = 200, headers: Dict[str, str] = None):
    h = {"Content-Type": "application/json", **CORS}
    if headers:
        h.update(headers)
    return {"statusCode": status, "headers": h, "body": json.dumps(body)}

def _parse_event(event) -> Tuple[str, str, Dict[str, Any], str]:
    path = event.get("path") or event.get("rawPath") or "/"
    method = (event.get("httpMethod") or event.get("requestContext", {}).get("http", {}).get("method") or "GET").upper()
    try:
        body_raw = event.get("body") or ""
        if event.get("isBase64Encoded"):
            import base64
            body_raw = base64.b64decode(body_raw).decode("utf-8")
        body = json.loads(body_raw) if body_raw else {}
    except Exception:
        body = {}
    return path, method, body, body_raw

def _service_info():
    return {
        "service": os.getenv("SERVICE", "hc"),
        "function": "pacientes",
        "stage": os.getenv("STAGE", "dev"),
        "rds_proxy": os.getenv("RDS_PROXY_ENDPOINT", ""),
        "s3_adjuntos": os.getenv("S3_ADJUNTOS_BUCKET", ""),
    }

# ---------- Handlers de negocio (mock por ahora) ----------
def list_pacientes(limit: int = 10):
    items = [{"id": i, "nombre": f"Paciente {i}"} for i in range(1, limit + 1)]
    return _resp({"ok": True, "items": items, **_service_info()})

def create_paciente(payload: Dict[str, Any]):
    required = ["nombre", "documento"]
    missing = [k for k in required if k not in payload]
    if missing:
        return _resp({"ok": False, "error": f"Faltan campos: {', '.join(missing)}"}, 400)
    nuevo = {
        "id": 1,  # mock
        "nombre": payload["nombre"],
        "documento": payload["documento"],
    }
    return _resp({"ok": True, "paciente": nuevo, **_service_info()}, 201)

# ---------- Lambda entry ----------
def handler(event, context):
    try:
        path, method, body, _ = _parse_event(event)

        # Rutas
        if path in ("/health", "/pacientes/health"):
            return _resp({"ok": True, **_service_info()})

        if path in ("/version", "/pacientes/version"):
            return _resp({"ok": True, "version": "0.1.0", **_service_info()})

        if path in ("/echo", "/pacientes/echo") and method == "POST":
            return _resp({"ok": True, "echo": body, **_service_info()})

        if path == "/pacientes" and method == "GET":
            qs = event.get("queryStringParameters") or {}
            try:
                limit = int(qs.get("limit", "10"))
            except ValueError:
                limit = 10
            return list_pacientes(limit=limit)

        if path == "/pacientes" and method == "POST":
            return create_paciente(body)

        # OPTIONS preflight CORS
        if method == "OPTIONS":
            return _resp({}, 204)

        return _resp({"ok": False, "error": "Not Found", "path": path}, 404)

    except Exception as e:
        # Log mínimo
        print("ERROR:", repr(e))
        return _resp({"ok": False, "error": "Internal Server Error"}, 500)

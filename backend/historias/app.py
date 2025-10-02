import json
import os
from typing import Any, Dict, Tuple

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
        "function": "historias",
        "stage": os.getenv("STAGE", "dev"),
        "rds_proxy": os.getenv("RDS_PROXY_ENDPOINT", ""),
        "s3_adjuntos": os.getenv("S3_ADJUNTOS_BUCKET", ""),
    }

def list_historias(paciente_id: str):
    # mock simple
    items = [
        {"id": "h-1", "paciente_id": paciente_id, "titulo": "Consulta inicial"},
        {"id": "h-2", "paciente_id": paciente_id, "titulo": "Control mensual"},
    ]
    return _resp({"ok": True, "items": items, **_service_info()})

def create_historia(payload: Dict[str, Any]):
    if "paciente_id" not in payload or "titulo" not in payload:
        return _resp({"ok": False, "error": "paciente_id y titulo son requeridos"}, 400)
    nueva = {"id": "h-100", **payload}
    return _resp({"ok": True, "historia": nueva, **_service_info()}, 201)

def handler(event, context):
    try:
        path, method, body, _ = _parse_event(event)

        if path in ("/health", "/historias/health"):
            return _resp({"ok": True, **_service_info()})

        if path in ("/version", "/historias/version"):
            return _resp({"ok": True, "version": "0.1.0", **_service_info()})

        if path in ("/echo", "/historias/echo") and method == "POST":
            return _resp({"ok": True, "echo": body, **_service_info()})

        # /historias?paciente_id=123
        if path == "/historias" and method == "GET":
            qs = event.get("queryStringParameters") or {}
            paciente_id = qs.get("paciente_id")
            if not paciente_id:
                return _resp({"ok": False, "error": "paciente_id es requerido"}, 400)
            return list_historias(paciente_id)

        if path == "/historias" and method == "POST":
            return create_historia(body)

        if method == "OPTIONS":
            return _resp({}, 204)

        return _resp({"ok": False, "error": "Not Found", "path": path}, 404)

    except Exception as e:
        print("ERROR:", repr(e))
        return _resp({"ok": False, "error": "Internal Server Error"}, 500)

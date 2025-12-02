# backend/episodios/app.py
import json
import os
from typing import Any, Dict

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
}

def _resp(body: Any, status: int = 200, headers: Dict[str, str] = None):
    h = {"Content-Type": "application/json", **CORS}
    if headers:
        h.update(headers)
    return {
        "statusCode": status,
        "headers": h,
        "body": json.dumps(body),
    }

def handler(event, context):
    method = (event.get("httpMethod") or
              event.get("requestContext", {}).get("http", {}).get("method") or
              "GET").upper()

    if method == "OPTIONS":
        return _resp({}, 204)

    body = {
        "service": os.getenv("SERVICE", "hc"),
        "function": "episodios",   # antes decía "adjuntos"
        "stage": os.getenv("STAGE", "dev"),
        "ok": True,
    }
    return _resp(body, 200)

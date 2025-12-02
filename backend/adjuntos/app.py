# backend/adjuntos/app.py
import json
import os


def handler(event, context):
    """
    Handler mínimo de adjuntos.
    Lee SERVICE desde variables de entorno (para poder mockearla en tests)
    y expone un JSON simple de health.
    """
    service = os.getenv("SERVICE", "adjuntos")

    body = {
        "service": service,
        "function": "adjuntos",
        "ok": True,
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }

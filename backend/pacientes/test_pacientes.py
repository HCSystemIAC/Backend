# backend/pacientes/test_pacientes.py
import json

from pacientes.app import handler  # 👈 importando el handler correcto


def test_health_ok():
    """
    Verifica que /health devuelve 200 y ok=True.
    """
    event = {
        "path": "/health",
        "httpMethod": "GET",
        "queryStringParameters": None,
        "body": None,
        "isBase64Encoded": False,
        "requestContext": {},
    }

    resp = handler(event, None)

    assert resp["statusCode"] == 200

    body = json.loads(resp["body"])
    assert body["ok"] is True
    assert body["function"] == "pacientes"


def test_list_pacientes_ok():
    """
    Verifica que /pacientes (GET) responde 200 y devuelve 3 pacientes
    cuando limit=3.
    """
    event = {
        "path": "/pacientes",
        "httpMethod": "GET",
        "queryStringParameters": {"limit": "3"},
        "body": None,
        "isBase64Encoded": False,
        "requestContext": {},
    }

    resp = handler(event, None)

    assert resp["statusCode"] == 200

    body = json.loads(resp["body"])
    assert body["ok"] is True
    assert "items" in body
    assert len(body["items"]) == 3

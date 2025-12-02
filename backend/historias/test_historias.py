# backend/historias/test_historias.py
import json

from historias.app import handler  # 👈 importando el handler correcto


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
    assert body["function"] == "historias"


def test_list_historias_ok():
    """
    Verifica que /historias?paciente_id=123 responde 200 y devuelve items.
    """
    event = {
        "path": "/historias",
        "httpMethod": "GET",
        "queryStringParameters": {"paciente_id": "123"},
        "body": None,
        "isBase64Encoded": False,
        "requestContext": {},
    }

    resp = handler(event, None)

    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["ok"] is True
    assert "items" in body
    assert len(body["items"]) >= 1

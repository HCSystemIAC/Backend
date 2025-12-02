import json
from adjuntos.app import handler

def test_adjuntos_basic_ok():
    """
    Prueba mínima del Lambda adjuntos: siempre responde 200 y ok=True.
    """
    event = {
        "path": "/adjuntos",
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

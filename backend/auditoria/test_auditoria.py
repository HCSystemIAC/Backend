import json
from auditoria.app import handler


def test_auditoria_basic_ok():
    """
    Prueba mínima del Lambda auditoría: siempre responde 200 y ok=True.
    """
    event = {
        "path": "/auditoria",
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

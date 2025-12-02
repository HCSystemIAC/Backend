import json
from episodios.app import handler


def test_episodios_basic_ok():
    """
    Prueba mínima del Lambda episodios: responde 200 y ok=True.
    (Tu handler actual devuelve datos fijos.)
    """
    event = {
        "path": "/episodios",
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

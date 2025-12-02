# backend/pacientes/test_pacientes_mock.py
import json

from pacientes import app


def test_handler_usa_list_pacientes_mock(monkeypatch):
    """
    MOCK:
    Verifica que el handler de /pacientes llama a list_pacientes
    con el parámetro 'limit' correcto, usando un mock.
    """

    llamadas = {}

    def fake_list_pacientes(limit: int = 10):
        llamadas["limit"] = limit
        return app._resp(
            {"ok": True, "from_mock": True, "limit": limit},
            status=200,
        )

    # Reemplazamos la función real por el mock
    monkeypatch.setattr(app, "list_pacientes", fake_list_pacientes)

    event = {
        "path": "/pacientes",
        "httpMethod": "GET",
        "queryStringParameters": {"limit": "5"},
        "body": None,
        "isBase64Encoded": False,
        "requestContext": {},
    }

    resp = app.handler(event, None)

    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])

    assert body["ok"] is True
    assert body["from_mock"] is True
    assert body["limit"] == 5
    assert llamadas["limit"] == 5

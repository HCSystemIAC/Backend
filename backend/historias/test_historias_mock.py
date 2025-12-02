# backend/historias/test_historias_mock.py
import json

from historias import app


def test_handler_usa_list_historias_mock(monkeypatch):
    """
    MOCK:
    Verifica que el handler de /historias llama a list_historias
    con el paciente_id correcto, usando un mock.
    """

    llamadas = {}

    def fake_list_historias(paciente_id: str):
        llamadas["paciente_id"] = paciente_id
        return app._resp(
            {"ok": True, "from_mock": True, "paciente_id": paciente_id},
            status=200,
        )

    # Reemplazamos la función real por el mock
    monkeypatch.setattr(app, "list_historias", fake_list_historias)

    event = {
        "path": "/historias",
        "httpMethod": "GET",
        "queryStringParameters": {"paciente_id": "999"},
        "body": None,
        "isBase64Encoded": False,
        "requestContext": {},
    }

    resp = app.handler(event, None)

    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])

    assert body["ok"] is True
    assert body["from_mock"] is True
    assert body["paciente_id"] == "999"

    # Aserción clave del mock
    assert llamadas["paciente_id"] == "999"

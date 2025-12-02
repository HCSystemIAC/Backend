# backend/adjuntos/test_adjuntos_mock.py
import json

from adjuntos import app


def test_adjuntos_usa_service_de_env_mock(monkeypatch):
    """
    MOCK:
    Simula que la variable de entorno SERVICE vale 'hc-mock'
    y verifica que el handler la use en la respuesta.
    """

    # En lugar de parchear os.getenv, seteamos directamente la env var
    monkeypatch.setenv("SERVICE", "hc-mock")

    resp = app.handler({}, None)

    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])

    assert body["ok"] is True
    # Validamos que el handler tomó el valor mockeado
    assert body["service"] == "hc-mock"

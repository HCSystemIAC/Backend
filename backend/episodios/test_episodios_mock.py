# backend/episodios/test_episodios_mock.py
import json

from episodios import app


def test_episodios_usa_service_de_env_mock(monkeypatch):
    """
    MOCK:
    Simula SERVICE='hc-episodios-mock' y verifica que el handler
    usa ese valor en la respuesta.
    """

    def fake_getenv(key, default=None):
        if key == "SERVICE":
            return "hc-episodios-mock"
        return default

    monkeypatch.setattr(app.os, "getenv", fake_getenv)

    resp = app.handler({}, None)

    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])

    assert body["ok"] is True
    assert body["service"] == "hc-episodios-mock"

# backend/auditoria/test_auditoria_mock.py
import json

from auditoria import app


def test_auditoria_usa_service_de_env_mock(monkeypatch):
    """
    MOCK:
    Simula que SERVICE='hc-auditoria-mock' y verifica que el handler
    propaga ese valor en el body.
    """

    def fake_getenv(key, default=None):
        if key == "SERVICE":
            return "hc-auditoria-mock"
        return default

    monkeypatch.setattr(app.os, "getenv", fake_getenv)

    resp = app.handler({}, None)

    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])

    assert body["ok"] is True
    assert body["service"] == "hc-auditoria-mock"

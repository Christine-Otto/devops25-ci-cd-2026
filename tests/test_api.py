from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_add_endpoint():
    response = client.get("/add?a=2&b=3")
    assert response.status_code == 200
    assert response.json() == {"result": 5.0}


def test_version():
    response = client.get("/version")
    assert response.status_code == 200
    assert response.json() == {
        "version": "1.1",
        "environment": "demo",
    }

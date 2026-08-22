import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_healthz():
    """Verify healthcheck endpoint returns status 200 and ok."""
    response = client.get('/healthz')
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_unauthorized_access_returns_401():
    """Accessing protected endpoint without a token must return 401."""
    response = client.get('/notes')  # Update to '/api/notes' if defined with /api prefix
    assert response.status_code == 401

def test_invalid_token_returns_401():
    """Accessing protected endpoint with an invalid token must return 401."""
    response = client.get('/notes', headers={
        'Authorization': 'Bearer invalid.jwt.token'
    })  # Update to '/api/notes' if defined with /api prefix
    assert response.status_code == 401
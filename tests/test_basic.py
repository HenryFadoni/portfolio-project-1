import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_root_endpoint():
    """Test the root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data

def test_items_endpoint():
    """Test the items endpoint exists"""
    response = client.get("/items/")
    # Should return 200 or 500 (if DB not connected), but not 404
    assert response.status_code in [200, 500]

def test_docs_endpoint():
    """Test the API documentation endpoint"""
    response = client.get("/docs")
    assert response.status_code == 200

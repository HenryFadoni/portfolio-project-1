from fastapi import FastAPI
from app.core.database import engine
from app.models.item import Item
from app.routers import items

# Create database tables
Item.metadata.create_all(bind=engine)

# Create FastAPI application
app = FastAPI(
    title="Portfolio API",
    description="A simple FastAPI application with PostgreSQL integration",
    version="1.0.0"
)

# Health check endpoint
@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "ok"}

# Include routers
app.include_router(items.router)

# Root endpoint
@app.get("/")
def read_root():
    """Root endpoint"""
    return {"message": "Welcome to Portfolio API", "docs": "/docs"}

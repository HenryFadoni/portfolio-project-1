#!/usr/bin/env python3
"""
Local development runner for FastAPI application
"""
import os
import subprocess
import sys

def run_with_local_db():
    """Run the application with local database"""
    # Set environment variables for local development
    os.environ["DATABASE_URL"] = "postgresql://dbadmin:password@localhost:5432/portfolio_dev"
    
    # Run uvicorn
    try:
        subprocess.run([
            sys.executable, "-m", "uvicorn", 
            "app.main:app", 
            "--host", "0.0.0.0", 
            "--port", "8080", 
            "--reload"
        ], check=True)
    except KeyboardInterrupt:
        print("\nShutting down...")
    except subprocess.CalledProcessError as e:
        print(f"Error running application: {e}")
        sys.exit(1)

if __name__ == "__main__":
    print("Starting FastAPI application for local development...")
    print("Make sure PostgreSQL is running on localhost:5432")
    print("Database: portfolio_dev, User: dbadmin, Password: password")
    print("API will be available at: http://localhost:8080")
    print("API documentation: http://localhost:8080/docs")
    print()
    run_with_local_db()

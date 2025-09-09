import os
import boto3
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

def get_db_password():
    """Get database password from SSM Parameter Store if running in AWS"""
    ssm_param = os.getenv("DB_PASSWORD_SSM_PARAM")
    if ssm_param:
        try:
            ssm = boto3.client('ssm')
            response = ssm.get_parameter(Name=ssm_param, WithDecryption=True)
            return response['Parameter']['Value']
        except Exception as e:
            print(f"Failed to get password from SSM: {e}")
            return "password"  # fallback for local development
    return os.getenv("DB_PASSWORD", "password")

# Get database connection details from environment variables
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "portfolio_dev")
DB_USERNAME = os.getenv("DB_USERNAME", "dbadmin")
DB_PASSWORD = get_db_password()

# Construct database URL
DATABASE_URL = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Create SQLAlchemy engine
engine = create_engine(DATABASE_URL)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class for models
Base = declarative_base()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

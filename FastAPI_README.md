# FastAPI Portfolio Application

A production-ready FastAPI application with PostgreSQL integration, designed to run on AWS ECS with Terraform-managed infrastructure.

## 🚀 Features

- **FastAPI Framework**: Modern, fast web framework for building APIs
- **PostgreSQL Integration**: Full CRUD operations with SQLAlchemy ORM
- **Health Check Endpoint**: `/health` for load balancer health checks
- **Items API**: Complete CRUD operations for items management
- **AWS Integration**: Works with RDS, SSM Parameter Store, and ECS
- **Docker Support**: Multi-stage build for optimal production deployment
- **Auto-documentation**: Interactive API docs at `/docs`

## 📁 Project Structure

```
app/
├── __init__.py
├── main.py                 # FastAPI application entry point
├── core/
│   ├── __init__.py
│   └── database.py         # Database configuration and connection
├── models/
│   ├── __init__.py
│   └── item.py            # SQLAlchemy models
├── schemas/
│   ├── __init__.py
│   └── item.py            # Pydantic schemas for request/response
├── crud/
│   ├── __init__.py
│   └── item.py            # CRUD operations
└── routers/
    ├── __init__.py
    └── items.py           # API route handlers
```

## 🛠 API Endpoints

### Health Check
- `GET /health` - Returns service health status

### Items Management
- `POST /items/` - Create a new item
- `GET /items/` - List all items (with pagination)
- `GET /items/{item_id}` - Get specific item by ID
- `PUT /items/{item_id}` - Update existing item
- `DELETE /items/{item_id}` - Delete item

### Documentation
- `GET /docs` - Interactive Swagger UI documentation
- `GET /redoc` - Alternative ReDoc documentation

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_NAME` | Database name | `portfolio_dev` |
| `DB_USERNAME` | Database username | `dbadmin` |
| `DB_PASSWORD` | Database password | `password` |
| `DB_PASSWORD_SSM_PARAM` | SSM parameter for password | - |

## 🏃‍♂️ Running Locally

### Option 1: Direct Python
```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables (optional)
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=portfolio_dev
export DB_USERNAME=dbadmin
export DB_PASSWORD=password

# Run the application
python run_local.py
```

### Option 2: Docker Compose
```bash
# Build and run with PostgreSQL
docker-compose up --build

# Access the application
curl http://localhost:8080/health
```

### Option 3: Docker Only
```bash
# Build the image
docker build -t portfolio-app .

# Run with environment variables
docker run -p 8080:8080 \
  -e DB_HOST=your-db-host \
  -e DB_NAME=your-db-name \
  portfolio-app
```

## 🗄 Database Models

### Item Model
```python
class Item:
    id: int (Primary Key)
    name: str (Required, Max 100 chars)
    description: str (Optional)
```

## 📝 API Usage Examples

### Create Item
```bash
curl -X POST "http://localhost:8080/items/" \
  -H "Content-Type: application/json" \
  -d '{"name": "Sample Item", "description": "This is a sample item"}'
```

### Get All Items
```bash
curl "http://localhost:8080/items/"
```

### Get Specific Item
```bash
curl "http://localhost:8080/items/1"
```

### Update Item
```bash
curl -X PUT "http://localhost:8080/items/1" \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Item", "description": "Updated description"}'
```

### Delete Item
```bash
curl -X DELETE "http://localhost:8080/items/1"
```

## 🚀 Deployment

### AWS ECS Deployment
The application is designed to work with the Terraform infrastructure in this repository:

1. **Build and push to ECR**:
   ```bash
   # Build image
   docker build -t portfolio-app .
   
   # Tag for ECR
   docker tag portfolio-app:latest YOUR_ACCOUNT.dkr.ecr.REGION.amazonaws.com/portfolio-app:latest
   
   # Push to ECR
   docker push YOUR_ACCOUNT.dkr.ecr.REGION.amazonaws.com/portfolio-app:latest
   ```

2. **Deploy with Terraform**:
   ```bash
   terraform apply
   ```

The application will automatically:
- Connect to the RDS PostgreSQL database
- Retrieve database password from SSM Parameter Store
- Register with the Application Load Balancer
- Send logs to CloudWatch

### Environment Configuration
- **Development**: Uses local database settings
- **Production**: Automatically integrates with AWS services
- **Database**: Supports both local PostgreSQL and AWS RDS
- **Secrets**: Uses SSM Parameter Store for secure password management

## 🔒 Security Features

- **Database passwords** stored in AWS SSM Parameter Store
- **Non-root container** user for security
- **Health checks** for container monitoring
- **Input validation** with Pydantic schemas
- **SQL injection protection** via SQLAlchemy ORM

## 📊 Monitoring

The application includes:
- Health check endpoint for load balancer monitoring
- Structured logging to CloudWatch (when deployed on AWS)
- Database connection error handling
- Graceful degradation for missing environment variables

## 🔧 Development

### Adding New Endpoints
1. Create new models in `app/models/`
2. Add Pydantic schemas in `app/schemas/`
3. Implement CRUD operations in `app/crud/`
4. Create API routes in `app/routers/`
5. Include router in `app/main.py`

### Database Migrations
For production use, consider adding Alembic for database migrations:
```bash
pip install alembic
alembic init alembic
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

## 🧪 Testing

Add tests by creating a `tests/` directory:
```bash
pip install pytest httpx
pytest tests/
```

## 📦 Production Considerations

- **Database connection pooling**: Already configured in SQLAlchemy
- **Error handling**: Comprehensive error responses
- **Logging**: Structured logging for CloudWatch
- **Performance**: Async/await support throughout
- **Scalability**: Stateless design for horizontal scaling

#!/bin/bash

# Portfolio Project Development Setup Script
# This script sets up the development environment for the FastAPI application

set -e

echo "🚀 Setting up Portfolio Project Development Environment"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if Python 3.11+ is installed
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        if [ "$(printf '%s\n' "3.11" "$PYTHON_VERSION" | sort -V | head -n1)" = "3.11" ]; then
            print_status "Python $PYTHON_VERSION found"
        else
            print_error "Python 3.11+ required, found $PYTHON_VERSION"
            exit 1
        fi
    else
        print_error "Python 3 not found. Please install Python 3.11+"
        exit 1
    fi
}

# Check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        print_status "Docker found"
    else
        print_warning "Docker not found. Install Docker for containerized development"
    fi
}

# Check if PostgreSQL is available
check_postgres() {
    if command -v psql &> /dev/null; then
        print_status "PostgreSQL client found"
    else
        print_warning "PostgreSQL client not found. Install for local database development"
    fi
}

# Create virtual environment
setup_venv() {
    if [ ! -d "venv" ]; then
        print_info "Creating Python virtual environment..."
        python3 -m venv venv
        print_status "Virtual environment created"
    else
        print_status "Virtual environment already exists"
    fi
}

# Activate virtual environment and install dependencies
install_dependencies() {
    print_info "Installing Python dependencies..."
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install dependencies
    pip install -r requirements.txt
    
    # Install development dependencies
    pip install flake8 pytest pytest-asyncio httpx black isort
    
    print_status "Dependencies installed"
}

# Create .env file for local development
create_env_file() {
    if [ ! -f ".env" ]; then
        print_info "Creating .env file for local development..."
        cat > .env << EOF
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=portfolio_dev
DB_USERNAME=dbadmin
DB_PASSWORD=password

# Application Configuration
ENVIRONMENT=development
PROJECT_NAME=portfolio

# Optional: AWS Configuration for local testing
# AWS_REGION=us-east-1
# AWS_ACCESS_KEY_ID=your-access-key
# AWS_SECRET_ACCESS_KEY=your-secret-key
EOF
        print_status ".env file created"
    else
        print_status ".env file already exists"
    fi
}

# Setup local database with Docker
setup_local_database() {
    if command -v docker &> /dev/null; then
        print_info "Setting up local PostgreSQL database..."
        
        # Check if container already exists
        if [ "$(docker ps -aq -f name=portfolio-postgres)" ]; then
            print_warning "PostgreSQL container already exists"
            if [ "$(docker ps -q -f name=portfolio-postgres)" ]; then
                print_status "PostgreSQL container is running"
            else
                print_info "Starting existing PostgreSQL container..."
                docker start portfolio-postgres
                print_status "PostgreSQL container started"
            fi
        else
            print_info "Creating new PostgreSQL container..."
            docker run -d \
                --name portfolio-postgres \
                -e POSTGRES_DB=portfolio_dev \
                -e POSTGRES_USER=dbadmin \
                -e POSTGRES_PASSWORD=password \
                -p 5432:5432 \
                postgres:15-alpine
            print_status "PostgreSQL container created and started"
        fi
        
        # Wait for database to be ready
        print_info "Waiting for database to be ready..."
        sleep 5
        
        # Test database connection
        if docker exec portfolio-postgres pg_isready -U dbadmin > /dev/null 2>&1; then
            print_status "Database is ready"
        else
            print_warning "Database may not be ready yet. Wait a few seconds and try connecting."
        fi
    else
        print_warning "Docker not available. Please set up PostgreSQL manually or use Docker Compose."
    fi
}

# Run initial tests
run_tests() {
    print_info "Running initial tests..."
    source venv/bin/activate
    
    # Run linting
    print_info "Running flake8 linting..."
    flake8 app --count --statistics || print_warning "Linting found issues"
    
    # Run tests
    print_info "Running pytest..."
    pytest tests/ -v || print_warning "Some tests failed"
    
    print_status "Test run completed"
}

# Create development scripts
create_dev_scripts() {
    # Create start script
    if [ ! -f "scripts/start-dev.sh" ]; then
        mkdir -p scripts
        cat > scripts/start-dev.sh << 'EOF'
#!/bin/bash
echo "Starting FastAPI development server..."
source venv/bin/activate
export $(cat .env | grep -v ^# | xargs)
python run_local.py
EOF
        chmod +x scripts/start-dev.sh
        print_status "Development start script created"
    fi
    
    # Create test script
    if [ ! -f "scripts/run-tests.sh" ]; then
        cat > scripts/run-tests.sh << 'EOF'
#!/bin/bash
echo "Running tests and linting..."
source venv/bin/activate
echo "Running flake8..."
flake8 app --statistics
echo "Running pytest..."
pytest tests/ -v
EOF
        chmod +x scripts/run-tests.sh
        print_status "Test script created"
    fi
    
    # Create format script
    if [ ! -f "scripts/format-code.sh" ]; then
        cat > scripts/format-code.sh << 'EOF'
#!/bin/bash
echo "Formatting code..."
source venv/bin/activate
black app/ tests/
isort app/ tests/
echo "Code formatted!"
EOF
        chmod +x scripts/format-code.sh
        print_status "Code formatting script created"
    fi
}

# Print helpful information
print_usage() {
    echo ""
    echo "🎉 Development environment setup complete!"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Activate virtual environment: source venv/bin/activate"
    echo "  2. Start development server: ./scripts/start-dev.sh"
    echo "  3. Run tests: ./scripts/run-tests.sh"
    echo "  4. Format code: ./scripts/format-code.sh"
    echo ""
    echo "🌐 URLs:"
    echo "  • API: http://localhost:8080"
    echo "  • API Docs: http://localhost:8080/docs"
    echo "  • Health Check: http://localhost:8080/health"
    echo ""
    echo "🗄 Database:"
    echo "  • Host: localhost:5432"
    echo "  • Database: portfolio_dev"
    echo "  • User: dbadmin"
    echo "  • Password: password"
    echo ""
    echo "🐳 Docker Commands:"
    echo "  • Start full stack: docker-compose up"
    echo "  • Stop database: docker stop portfolio-postgres"
    echo "  • View logs: docker logs portfolio-postgres"
    echo ""
}

# Main execution
main() {
    echo "Checking system requirements..."
    check_python
    check_docker
    check_postgres
    
    echo ""
    echo "Setting up development environment..."
    setup_venv
    install_dependencies
    create_env_file
    setup_local_database
    create_dev_scripts
    
    echo ""
    echo "Running initial validation..."
    run_tests
    
    print_usage
}

# Run main function
main "$@"

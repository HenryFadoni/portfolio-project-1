# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store password in AWS Systems Manager Parameter Store
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/${var.environment}/db/password"
  type  = "SecureString"
  value = random_password.db_password.result

  tags = {
    Name = "${var.project_name}-${var.environment}-db-password"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${var.project_name}-${var.environment}-db-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-params"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true
  multi_az              = var.environment == "prod" ? true : false

  db_name  = replace("${var.project_name}_${var.environment}", "-", "_")
  username = "dbadmin"
  password = random_password.db_password.result

  vpc_security_group_ids = [var.database_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot       = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "dev" ? null : "${var.project_name}-${var.environment}-final-snapshot"
  
  deletion_protection = var.environment == "prod" ? true : false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = var.monitoring_role_arn

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = "${var.project_name}-${var.environment}-database"
  }
}

# CloudWatch Log Group for RDS
resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/postgresql"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-logs"
  }
}

# RDS Proxy (optional, for connection pooling)
resource "aws_db_proxy" "main" {
  count = var.enable_rds_proxy ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-db-proxy"
  engine_family         = "POSTGRESQL"
  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.db_credentials[0].arn
  }
  role_arn               = aws_iam_role.proxy[0].arn
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.database_security_group_id]

  tags = {
    Name = "${var.project_name}-${var.environment}-db-proxy"
  }
}

# RDS Proxy Target
resource "aws_db_proxy_target" "main" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name          = aws_db_proxy.main[0].name
  db_instance_identifier = aws_db_instance.main.identifier
}

# Secrets Manager for RDS Proxy (if enabled)
resource "aws_secretsmanager_secret" "db_credentials" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${var.project_name}-${var.environment}-db-credentials"

  tags = {
    Name = "${var.project_name}-${var.environment}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count = var.enable_rds_proxy ? 1 : 0

  secret_id = aws_secretsmanager_secret.db_credentials[0].id
  secret_string = jsonencode({
    username = aws_db_instance.main.username
    password = random_password.db_password.result
  })
}

# IAM Role for RDS Proxy (if enabled)
resource "aws_iam_role" "proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-proxy-role"
  }
}

resource "aws_iam_role_policy" "proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-proxy-policy"
  role = aws_iam_role.proxy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_credentials[0].arn
      }
    ]
  })
}

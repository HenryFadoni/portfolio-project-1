locals {
  # Database connection components for environment variables
  db_host     = module.rds.db_instance_endpoint
  db_port     = module.rds.db_instance_port
  db_name     = module.rds.db_name
  db_username = module.rds.db_username
}

module "vpc" {
  source = "./modules/vpc"

  environment          = var.environment
  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs = var.public_subnet_cidrs
}

module "iam" {
  source = "./modules/iam"

  environment  = var.environment
  project_name = var.project_name
}

module "monitoring" {
  source = "./modules/monitoring"

  environment                = var.environment
  project_name              = var.project_name
  target_group_arn_suffix   = module.ecs.target_group_arn_suffix
  load_balancer_arn_suffix  = module.ecs.load_balancer_arn_suffix
}

module "rds" {
  source = "./modules/rds"

  environment                 = var.environment
  project_name               = var.project_name
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  database_security_group_id = module.vpc.database_security_group_id
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  monitoring_role_arn        = module.iam.rds_enhanced_monitoring_role_arn
}

module "ecs" {
  source = "./modules/ecs"

  environment               = var.environment
  project_name             = var.project_name
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  public_subnet_ids        = module.vpc.public_subnet_ids
  cluster_name             = var.ecs_cluster_name
  service_desired_count    = var.ecs_service_desired_count
  task_execution_role_arn  = module.iam.ecs_task_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn
  log_group_name          = module.monitoring.log_group_name
  db_host                 = local.db_host
  db_port                 = local.db_port
  db_name                 = local.db_name
  db_username             = local.db_username
  db_password_ssm_parameter = module.rds.db_password_ssm_parameter
}

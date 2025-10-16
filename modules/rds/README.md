# AWS RDS Database Terraform Module

This module creates an AWS RDS database instance with configurable options including Multi-AZ, read replicas, backups, and monitoring.

## Features

- Support for multiple database engines (PostgreSQL, MySQL, MariaDB, etc.)
- Multi-AZ deployment for high availability
- Read replica support
- Automated backups with configurable retention
- Encryption at rest
- Performance Insights
- Enhanced monitoring
- Custom parameter and option groups
- CloudWatch Logs integration

## Usage

### Basic PostgreSQL Example

```hcl
module "postgres_db" {
  source = "./modules/rds"

  db_identifier   = "myapp-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.small"

  database_name   = "myappdb"
  master_username = "dbadmin"
  master_password = var.db_password # Store in secrets manager!

  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.database.id]

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_encrypted     = true

  multi_az = true

  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  tags = {
    Environment = "production"
    Application = "myapp"
  }
}
```

### Advanced Example with Read Replicas

```hcl
module "mysql_db" {
  source = "./modules/rds"

  db_identifier   = "analytics-db"
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.r6g.xlarge"

  database_name   = "analytics"
  master_username = "admin"
  master_password = var.db_password

  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.database.id]

  # Storage configuration
  allocated_storage     = 500
  max_allocated_storage = 2000
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds.arn

  # High availability
  multi_az = true

  # Read replicas for analytics workload
  create_read_replica   = true
  read_replica_count    = 2
  replica_instance_class = "db.r6g.large"

  # Custom parameters
  parameter_group_family = "mysql8.0"
  db_parameters = [
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "innodb_buffer_pool_size"
      value = "{DBInstanceClassMemory*3/4}"
      apply_method = "pending-reboot"
    }
  ]

  # Monitoring and insights
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled    = true
  performance_insights_retention_period = 731

  # Backup configuration
  backup_retention_period = 30
  deletion_protection     = true

  tags = {
    Environment = "production"
    Workload    = "analytics"
  }
}
```

### PostgreSQL with Custom Options

```hcl
module "postgres_advanced" {
  source = "./modules/rds"

  db_identifier   = "app-postgres"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.m6g.2xlarge"

  database_name   = "appdb"
  master_username = "postgres"
  master_password = var.db_password

  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.postgres.id]

  # Parameter group with custom settings
  parameter_group_family = "postgres15"
  db_parameters = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements,pgaudit"
      apply_method = "pending-reboot"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]

  # CloudWatch logs
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  multi_az = true

  tags = {
    Environment = "production"
  }
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| db_identifier | Database identifier | string | n/a | yes |
| engine | Database engine | string | "postgres" | no |
| engine_version | Database engine version | string | n/a | yes |
| instance_class | Database instance class | string | "db.t3.micro" | no |
| database_name | Name of the default database | string | n/a | yes |
| master_username | Master username | string | n/a | yes |
| master_password | Master password | string | n/a | yes |
| subnet_ids | List of subnet IDs | list(string) | n/a | yes |
| vpc_security_group_ids | List of security group IDs | list(string) | n/a | yes |
| allocated_storage | Allocated storage in GB | number | 20 | no |
| storage_type | Storage type | string | "gp3" | no |
| storage_encrypted | Enable encryption | bool | true | no |
| multi_az | Enable Multi-AZ | bool | false | no |
| backup_retention_period | Backup retention in days | number | 7 | no |
| deletion_protection | Enable deletion protection | bool | true | no |
| create_read_replica | Create read replicas | bool | false | no |
| read_replica_count | Number of read replicas | number | 1 | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_endpoint | Connection endpoint |
| db_instance_address | Hostname |
| db_instance_port | Database port |
| db_instance_name | Database name |
| read_replica_endpoints | Read replica endpoints |

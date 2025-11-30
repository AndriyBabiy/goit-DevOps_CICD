# =============================================================================
# STANDARD RDS INSTANCE
# Created when use_aurora = false
# =============================================================================

resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier = var.identifier

  # Engine Configuration
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.this[0].name

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true

  # Database Configuration
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.port

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled
  # CloudWatch Logs: Use provided list if not empty, otherwise use engine-appropriate defaults
  enabled_cloudwatch_logs_exports = (
    length(var.enabled_cloudwatch_logs_exports) > 0
    ? var.enabled_cloudwatch_logs_exports
    : (var.engine == "postgres" ? ["postgresql"] :
       contains(["mysql", "mariadb"], var.engine) ? ["error", "slowquery"] : [])
  )

  # Lifecycle
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot"
  deletion_protection       = var.deletion_protection
  apply_immediately         = true

  tags = merge(var.tags, {
    Name = var.identifier
  })
}

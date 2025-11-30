# =============================================================================
# AURORA CLUSTER
# Created when use_aurora = true
# =============================================================================

# -----------------------------------------------------------------------------
# Aurora Cluster
# -----------------------------------------------------------------------------
resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = var.identifier

  # Engine Configuration
  engine         = var.engine
  engine_version = var.engine_version

  # Use cluster parameter group
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name

  # Database Configuration
  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password
  port            = var.port

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  # Storage (Aurora handles this automatically)
  storage_encrypted = true

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  # Lifecycle
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot"
  deletion_protection       = var.deletion_protection
  apply_immediately         = true

  # CloudWatch Logs: Use provided list if not empty, otherwise use engine-appropriate defaults
  enabled_cloudwatch_logs_exports = (
    length(var.enabled_cloudwatch_logs_exports) > 0
    ? var.enabled_cloudwatch_logs_exports
    : (var.engine == "aurora-postgresql" ? ["postgresql"] :
       var.engine == "aurora-mysql" ? ["error", "slowquery"] : [])
  )

  tags = merge(var.tags, {
    Name = var.identifier
  })
}

# -----------------------------------------------------------------------------
# Aurora Cluster Instances (Writer + Readers)
# -----------------------------------------------------------------------------
resource "aws_rds_cluster_instance" "this" {
  count = var.use_aurora ? var.aurora_instance_count : 0

  identifier         = "${var.identifier}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this[0].id

  # Engine (must match cluster)
  engine         = var.engine
  engine_version = var.engine_version

  # Instance Configuration
  instance_class = var.instance_class

  # Network
  db_subnet_group_name = aws_db_subnet_group.this.name
  publicly_accessible  = var.publicly_accessible

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled

  # Apply changes immediately
  apply_immediately = true

  tags = merge(var.tags, {
    Name = "${var.identifier}-instance-${count.index + 1}"
    Role = count.index == 0 ? "writer" : "reader"
  })
}

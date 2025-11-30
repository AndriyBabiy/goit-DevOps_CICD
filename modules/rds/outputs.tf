# =============================================================================
# OUTPUTS - Common Information
# =============================================================================

output "identifier" {
  description = "Database identifier"
  value       = var.identifier
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.this.id
}

output "port" {
  description = "Database port"
  value       = var.port
}

# =============================================================================
# OUTPUTS - RDS Instance (when use_aurora = false)
# =============================================================================

output "rds_instance_endpoint" {
  description = "RDS Instance endpoint"
  value       = var.use_aurora ? null : aws_db_instance.this[0].endpoint
}

output "rds_instance_address" {
  description = "RDS Instance hostname"
  value       = var.use_aurora ? null : aws_db_instance.this[0].address
}

output "rds_instance_arn" {
  description = "RDS Instance ARN"
  value       = var.use_aurora ? null : aws_db_instance.this[0].arn
}

output "rds_instance_id" {
  description = "RDS Instance ID"
  value       = var.use_aurora ? null : aws_db_instance.this[0].id
}

# =============================================================================
# OUTPUTS - Aurora Cluster (when use_aurora = true)
# =============================================================================

output "aurora_cluster_endpoint" {
  description = "Aurora Cluster writer endpoint"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : null
}

output "aurora_cluster_reader_endpoint" {
  description = "Aurora Cluster reader endpoint"
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}

output "aurora_cluster_arn" {
  description = "Aurora Cluster ARN"
  value       = var.use_aurora ? aws_rds_cluster.this[0].arn : null
}

output "aurora_cluster_id" {
  description = "Aurora Cluster ID"
  value       = var.use_aurora ? aws_rds_cluster.this[0].id : null
}

output "aurora_instance_endpoints" {
  description = "List of Aurora instance endpoints"
  value       = var.use_aurora ? aws_rds_cluster_instance.this[*].endpoint : []
}

# =============================================================================
# OUTPUTS - Unified Connection Information
# =============================================================================

output "connection_endpoint" {
  description = "Primary connection endpoint (works for both Aurora and RDS)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].endpoint
}

output "connection_address" {
  description = "Primary connection hostname (without port)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "database_name" {
  description = "Name of the default database"
  value       = var.database_name
}

output "master_username" {
  description = "Master username"
  value       = var.master_username
}

# =============================================================================
# OUTPUTS - Connection String Helper
# =============================================================================

locals {
  # Determine connection protocol based on engine type
  connection_protocol = contains(["postgres", "aurora-postgresql"], var.engine) ? "postgresql" : "mysql"
}

output "connection_string" {
  description = "Connection string template (replace <PASSWORD> with actual password)"
  value = format(
    "%s://%s:<PASSWORD>@%s:%d/%s",
    local.connection_protocol,
    var.master_username,
    var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address,
    var.port,
    var.database_name
  )
  sensitive = false
}

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "identifier" {
  description = "Unique identifier for the database resources"
  type        = string
}

variable "use_aurora" {
  description = "Whether to create Aurora Cluster (true) or RDS Instance (false)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

variable "vpc_id" {
  description = "VPC ID where database will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (minimum 2 for Aurora)"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = []
}

# =============================================================================
# DATABASE ENGINE CONFIGURATION
# =============================================================================

variable "engine" {
  description = "Database engine (postgres, mysql, aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "postgres"

  validation {
    condition = contains([
      "postgres", "mysql", "mariadb",
      "aurora-postgresql", "aurora-mysql"
    ], var.engine)
    error_message = "Engine must be one of: postgres, mysql, mariadb, aurora-postgresql, aurora-mysql."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.13"
}

variable "instance_class" {
  description = "Instance class for the database"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB (only for RDS Instance, not Aurora)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling in GB (only for RDS Instance)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

# =============================================================================
# DATABASE SETTINGS
# =============================================================================

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

# =============================================================================
# HIGH AVAILABILITY & BACKUP
# =============================================================================

variable "multi_az" {
  description = "Enable Multi-AZ deployment (only for RDS Instance)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

# =============================================================================
# AURORA-SPECIFIC SETTINGS
# =============================================================================

variable "aurora_instance_count" {
  description = "Number of Aurora instances (1 writer + N-1 readers)"
  type        = number
  default     = 2
}

# =============================================================================
# PARAMETER GROUP SETTINGS
# =============================================================================

variable "parameter_group_family" {
  description = "Parameter group family (e.g., postgres15, aurora-postgresql15)"
  type        = string
  default     = "postgres15"
}

variable "db_parameters" {
  description = "Map of database parameters to set. NOTE: Default values are PostgreSQL-specific. For MySQL, override with MySQL-compatible parameters."
  type = map(object({
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = {
    # PostgreSQL-specific defaults (override for MySQL/MariaDB)
    "max_connections" = {
      value        = "200"
      apply_method = "pending-reboot"  # Static parameter - requires restart
    }
    "log_statement" = {
      value = "all"
      # Dynamic parameter - can apply immediately (PostgreSQL only)
    }
    "work_mem" = {
      value = "16384"  # 16MB in KB (PostgreSQL only)
      # Dynamic parameter - can apply immediately
    }
  }
}

# =============================================================================
# ADDITIONAL SETTINGS
# =============================================================================

variable "publicly_accessible" {
  description = "Whether the database should be publicly accessible"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying database"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch. If empty, engine-appropriate defaults are used (postgresql: ['postgresql'], mysql: ['error', 'slowquery'])"
  type        = list(string)
  default     = []
}

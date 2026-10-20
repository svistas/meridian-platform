# The recipe.
#
# Every property in the build brief's guarantee table is fixed here. None of
# them is a variable, so no request file can turn one off. PHI-grade defaults
# apply to every datastore whatever its classification (ADR-0002), which is why
# classification is only a tag below.

locals {
  sizes = {
    small  = { instance_class = "db.t4g.micro", allocated_storage = 20 }
    medium = { instance_class = "db.t4g.small", allocated_storage = 50 }
  }

  size = local.sizes[var.size]

  tags = {
    service        = var.service
    team           = var.team
    "cost-center"  = var.cost_center
    classification = var.classification
    "managed-by"   = "meridian-platform"
    path           = "compliant-datastore"

    # Recorded so the inventory can show it; the flag itself is raised by
    # validate_requests.py, not here.
    "data-leaves-meridian" = var.data_leaves_meridian
  }
}

# TLS is enforced in the parameter group. rds.force_ssl is a static parameter,
# so it takes effect on reboot; RDS reboots the instance when it is created
# with this group attached.
resource "aws_db_parameter_group" "this" {
  name        = "${var.service}-postgres"
  family      = "postgres${split(".", var.engine_version)[0]}"
  description = "Compliant datastore defaults for ${var.service}"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # Who connected and when. Dynamic parameters, so they take effect without a
  # reboot.
  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_disconnections"
    value        = "1"
    apply_method = "immediate"
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# No ingress rules: nothing can reach the database yet. Path 02 is what
# connects a running service to it.
resource "aws_security_group" "this" {
  name        = "${var.service}-postgres"
  description = "Datastore for ${var.service}. No ingress until a service is attached."
  vpc_id      = var.vpc_id

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# RDS creates these log groups itself on first export, with no retention set,
# which means logs are kept forever and cost money forever. Creating them here
# first fixes the retention at 90 days.
resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${var.service}/postgresql"
  retention_in_days = 90
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "upgrade" {
  name              = "/aws/rds/instance/${var.service}/upgrade"
  retention_in_days = 90
  tags              = local.tags
}

resource "aws_db_instance" "this" {
  identifier = var.service

  engine         = "postgres"
  engine_version = var.engine_version
  db_name        = replace(var.service, "-", "_")

  instance_class    = local.size.instance_class
  allocated_storage = local.size.allocated_storage
  storage_type      = "gp3"

  # Guarantee: storage encrypted with the platform's customer-managed key.
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Guarantee: never reachable from the internet; private subnets only.
  publicly_accessible    = false
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.this.id]

  # Guarantee: 35-day backups.
  backup_retention_period = 35

  # Guarantee: TLS enforced.
  parameter_group_name = aws_db_parameter_group.this.name

  # Guarantee: Postgres logs exported to CloudWatch.
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Guarantee: the master password is generated and held by RDS in Secrets
  # Manager. It is never in Terraform state, in a variable, or in an output.
  username                      = "meridian"
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  # Guarantee: tags.
  tags                  = local.tags
  copy_tags_to_snapshot = true

  # Sandbox only (ADR-0003): single AZ, no deletion protection, no final
  # snapshot, so a teardown really tears down.
  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true

  auto_minor_version_upgrade = true

  # The log groups must exist before RDS starts exporting into them, or RDS
  # creates them itself with no retention.
  depends_on = [
    aws_cloudwatch_log_group.postgresql,
    aws_cloudwatch_log_group.upgrade,
  ]
}

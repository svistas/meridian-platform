# Everything the path needs from the bootstrap is passed in explicitly. No
# account id, key id, subnet id or VPC id is written down in this repository:
# the values come from `terraform output` in platform/bootstrap, and in CI from
# repository variables (phase 4).

variable "region" {
  description = "The sandbox region (ADR-0003)."
  type        = string
  default     = "eu-west-1"
}

variable "kms_key_arn" {
  description = "Bootstrap output kms_key_arn. Every datastore is encrypted with this key."
  type        = string
}

variable "db_subnet_group_name" {
  description = "Bootstrap output db_subnet_group_name. Private subnets only."
  type        = string
}

variable "vpc_id" {
  description = "Bootstrap output vpc_id. The security group for each datastore lives here."
  type        = string
}

variable "engine_version" {
  description = "Major Postgres version for every datastore. Major only: RDS picks the current minor, and auto_minor_version_upgrade keeps it current."
  type        = string
  default     = "17"
}

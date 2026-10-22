# The brief asks for the role ARN and the bucket name. There are two roles now
# (ADR-0004), so both are output.

output "ci_plan_role_arn" {
  description = "Assumed by pull-request workflows. Read-only."
  value       = aws_iam_role.ci_plan.arn
}

output "ci_apply_role_arn" {
  description = "Assumed by workflows on main. Can create and destroy datastores."
  value       = aws_iam_role.ci_apply.arn
}

output "state_bucket_name" {
  description = "Backend bucket for every later phase."
  value       = aws_s3_bucket.state.id
}

# Needed by phase 2 so the path's Terraform does not hard-code account details.

output "kms_key_arn" {
  description = "The key every datastore is encrypted with."
  value       = aws_kms_key.datastores.arn
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "datastore_clients_security_group_id" {
  description = "Membership group. Path 01 databases accept connections from it; path 02 nodes join it."
  value       = aws_security_group.datastore_clients.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.datastores.name
}

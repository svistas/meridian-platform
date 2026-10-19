# The two the build brief asks for.

output "ci_role_arn" {
  description = "Set this as the repository variable the workflows read (phase 4)."
  value       = aws_iam_role.ci.arn
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

output "db_subnet_group_name" {
  value = aws_db_subnet_group.datastores.name
}

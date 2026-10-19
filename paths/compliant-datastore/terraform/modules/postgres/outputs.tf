output "identifier" {
  value = aws_db_instance.this.identifier
}

output "endpoint" {
  value = aws_db_instance.this.endpoint
}

output "port" {
  value = aws_db_instance.this.port
}

# The ARN only. Reading the password is a separate, audited call against
# Secrets Manager by whoever needs it.
output "master_user_secret_arn" {
  value = one(aws_db_instance.this.master_user_secret[*].secret_arn)
}

output "classification" {
  value = var.classification
}

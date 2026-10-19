# The password is never output: it is managed by RDS in Secrets Manager and the
# developer reads it from there. Only the ARN of the secret is published.

output "datastores" {
  description = "One entry per request file."
  value = {
    for name, m in module.postgres : name => {
      identifier     = m.identifier
      endpoint       = m.endpoint
      port           = m.port
      secret_arn     = m.master_user_secret_arn
      classification = m.classification
    }
  }
}

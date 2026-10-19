variable "region" {
  description = "The single region the sandbox runs in (ADR-0003)."
  type        = string
  default     = "eu-west-1"
}

variable "github_repository" {
  description = "The only repository allowed to assume the CI role, as owner/name."
  type        = string
  default     = "svistas/meridian-platform"
}

variable "budget_limit_usd" {
  description = "Monthly budget for the whole sandbox account (ADR-0003)."
  type        = string
  default     = "20"
}

variable "budget_alert_email" {
  description = "Address that receives budget alerts. No default: set it in terraform.tfvars, which is gitignored. See terraform.tfvars.example."
  type        = string
}

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

# GitHub identifies the repository in an OIDC subject by numeric id as well as
# by name. These ids are public -- `gh api repos/svistas/meridian-platform`
# returns them to anyone who can see the repository -- so they are variables
# with defaults, not secrets.

variable "github_owner_id" {
  description = "Numeric id of the GitHub account that owns the repository."
  type        = string
  default     = "150247420"
}

variable "github_repo_id" {
  description = "Numeric id of the repository itself."
  type        = string
  default     = "1422352369"
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

# Everything that persists between sessions comes from the bootstrap and is
# passed in explicitly, as path 01 does. Nothing here hard-codes an account.

variable "region" {
  description = "The sandbox region (ADR-0003)."
  type        = string
  default     = "eu-west-1"
}

variable "vpc_id" {
  description = "Bootstrap output vpc_id."
  type        = string
}

variable "private_subnet_ids" {
  description = "Bootstrap output private_subnet_ids. The cluster and its nodes live here."
  type        = list(string)
}

variable "ci_apply_role_arn" {
  description = "Bootstrap output ci_apply_role_arn. Given an EKS access entry so CI can deploy (sandbox debt, ADR-0006)."
  type        = string
}

variable "datastore_clients_security_group_id" {
  description = <<-EOT
    Bootstrap output datastore_clients_security_group_id. Nodes join this
    group, which is what lets them reach path 01 databases. The session never
    edits a datastore's own security group.
  EOT
  type        = string
}

variable "public_subnet_cidr" {
  description = "A /24 inside the bootstrap VPC for the NAT gateway. The bootstrap uses 10.20.1.0/24 and 10.20.2.0/24."
  type        = string
  default     = "10.20.0.0/24"
}

variable "kubernetes_version" {
  description = "EKS version. 1.37 is the current default and in standard support until 2027-12-01."
  type        = string
  default     = "1.37"
}

variable "node_instance_types" {
  description = <<-EOT
    Instance types the node group may choose from, cheapest first. More than
    one type means a spot shortage in one pool does not leave the session
    without nodes. All ARM, to match the AL2023_ARM_64_STANDARD image.
  EOT
  type        = list(string)
  default     = ["t4g.small", "t4g.medium", "m6g.medium", "m7g.medium"]
}

variable "node_count" {
  description = "Two nodes, so a spot reclaim does not take the whole cluster."
  type        = number
  default     = 2
}

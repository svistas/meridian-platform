# From the request file.

variable "service" {
  description = "Service the datastore belongs to. Becomes the identifier."
  type        = string
}

variable "team" {
  type = string
}

variable "cost_center" {
  type = string
}

variable "classification" {
  description = "phi | non-phi | unsure. Recorded as a tag; it does not change what is built."
  type        = string
}

variable "size" {
  description = "small | medium."
  type        = string

  validation {
    condition     = contains(["small", "medium"], var.size)
    error_message = "size must be small or medium."
  }
}

variable "data_leaves_meridian" {
  description = "Recorded as a tag. Judgment cases are flagged in phase 3, not here."
  type        = string
}

# From the bootstrap.

variable "kms_key_arn" {
  type = string
}

variable "db_subnet_group_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "engine_version" {
  type = string
}

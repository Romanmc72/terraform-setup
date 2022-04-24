variable region {
  type        = string
  description = "The AWS Region for these resources."
}

variable environment {
  type        = string
  description = "The environment these resources are associated with (local|dev|qa|stg|prod)."
  default     = "dev"
}

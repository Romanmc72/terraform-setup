variable region {
  type        = string
  description = "The AWS Region into which the following resources will be applied."
  default     = "us-east-1" 
}

variable account_id {
  type        = string
  description = "The AWS Account ID that you will be deploying to."
  default     = "005071865344"
}

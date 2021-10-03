variable app_name {
  # REQUIRED
  type        = string
  description = "The name of this application. Try to use a name that is compatible with various naming conventions, avoid spaces, underscores, and hyphens."
}

variable image_name {
  # REQUIRED
  type        = string
  description = "The name of the ECR image that will be deployed as the lambda."
}

variable image_tag {
  # REQUIRED
  type        = string
  description = "The specific tag of the image that you wish to deploy."
}

variable stage_name {
  # REQUIRED
  type        = string
  description = "The 'stage' that will be deployed, representing the slug of the api endpoint."
}

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

variable environment {
  type        = string
  description = "The tag representing which aws environment that this bundle of resources will be associated with. Use one of the following: (local|dev|qa|stg|prod)."
  default     = "dev"
}

variable lambda_env_vars {
  type        = map(any)
  description = "Any env var values that you wish to pass to your lambda when it runs."
  default     = {}
}

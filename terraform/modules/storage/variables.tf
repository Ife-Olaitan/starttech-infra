variable "name" {
  description = "Project name prefix for resource naming"
  type        = string
}


variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "oac_name" {
  description = "Name of the CloudFront Origin Access Control"
  type        = string
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo-name'"
  type        = string
}
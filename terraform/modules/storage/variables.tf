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
# Networking
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

# Storage (Frontend)
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.storage.cloudfront_domain_name
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = module.storage.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = module.storage.cloudfront_distribution_id
}


# Compute (Backend)
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = module.compute.redis_endpoint
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}

# Monitoring
output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = module.monitoring.log_group_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = module.monitoring.sns_topic_arn
}

# Github OIDC
output "github_actions_frontend_role_arn" {
  description = "ARN of the GitHub Actions role for frontend deployment"
  value       = module.storage.github_actions_role_arn
}

output "github_actions_backend_role_arn" {
  description = "ARN of the GitHub Actions role for backend deployment"
  value       = module.compute.github_actions_role_arn
}
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.starttech_bucket.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.starttech_bucket.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution (for cache invalidation)"
  value       = aws_cloudfront_distribution.starttech_distribution.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.starttech_distribution.domain_name
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role for frontend deployment"
  value       = aws_iam_role.github_actions_frontend.arn
}
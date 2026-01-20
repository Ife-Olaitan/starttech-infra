terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.1"
    }
  }
}

# Reference existing S3 bucket
data "aws_s3_bucket" "my_bucket" {
  bucket = "much-to-do"
}

# Create Origin Access Identity for CloudFront
resource "aws_cloudfront_origin_access_identity" "my_oai" {
  comment = "OAI for much-to-do bucket"
}

# Bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = data.aws_s3_bucket.my_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = aws_cloudfront_origin_access_identity.my_oai.iam_arn }
      Action    = "s3:GetObject"
      Resource  = "${data.aws_s3_bucket.my_bucket.arn}/*"
    }]
  })
}

resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name = data.aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "s3-origin"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my_oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
}
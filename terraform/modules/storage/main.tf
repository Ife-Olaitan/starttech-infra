# S3 Bucket
resource "aws_s3_bucket" "starttech_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "${var.name}-s3-bucket"
  }
}

# Bucket Policy Doc
data "aws_iam_policy_document" "origin_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.starttech_bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.starttech_distribution.arn]
    }
  }
}

# Bucket Policy
resource "aws_s3_bucket_policy" "starttech_bucket_policy" {
  bucket = aws_s3_bucket.starttech_bucket.id
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

# Origin Access Control for CloudFront
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = var.oac_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "starttech_distribution" {
  origin {
    domain_name              = aws_s3_bucket.starttech_bucket.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.default_root_object

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

  tags = {
    Name = "${var.name}-frontend-distribution"
  }
}

# IAM Role for GitHub Actions Frontend Deploy
resource "aws_iam_role" "github_actions_frontend" {
  name = "${var.name}-github-actions-frontend"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.github_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })
}

# Policy for S3 and CloudFront access
resource "aws_iam_role_policy" "github_actions_frontend" {
  name = "frontend-deploy-policy"
  role = aws_iam_role.github_actions_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.starttech_bucket.arn,
          "${aws_s3_bucket.starttech_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = "*"
      }
    ]
  })
}

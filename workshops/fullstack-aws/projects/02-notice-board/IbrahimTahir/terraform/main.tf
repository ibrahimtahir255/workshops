terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name = "student-${var.student_name}-notice-board"
}

# ---------------------------------------------------------------------------
# TIER 1 TODOs
# ---------------------------------------------------------------------------

resource "aws_lambda_function" "lambda_function"{
  filename = "${path.module}/../backend/lambda.zip"
  handler  = "lambda_function.lambda_handler"
  runtime  = "python3.12"
  environment { 
    variables = { 
      MONGO_HOST = var.mongo_host,
      MONGO_PORT = var.mongo_port
      }
  }
  role = "arn:aws:iam::279249498881:role/quicklabs-fullstack-shared-lambda-exec" 
  function_name = "${local.name}-lambda-function"
}

resource "aws_apigatewayv2_api" "api_gateway" {
  protocol_type = "HTTP"
  name = "${local.name}-apigateway"
}

resource "aws_apigatewayv2_integration" "api_gateway_integration"{
  #   - integration_type = "AWS_PROXY", connects the api to the lambda
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.lambda_function.invoke_arn
  api_id = aws_apigatewayv2_api.api_gateway.id
  payload_format_version = "2.0"
  integration_method = "POST"
}


#  "aws_apigatewayv2_route x3
#   - "GET /notices", "POST /notices", "DELETE /notices/{id}"

resource "aws_apigatewayv2_route" "get_notices" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /notices"
  target = "integrations/${aws_apigatewayv2_integration.api_gateway_integration.id}"
}

resource "aws_apigatewayv2_route" "post_notices" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  route_key = "POST /notices"
  target = "integrations/${aws_apigatewayv2_integration.api_gateway_integration.id}"
}

resource "aws_apigatewayv2_route" "delete_notice" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  route_key = "DELETE /notices/{id}"
  target = "integrations/${aws_apigatewayv2_integration.api_gateway_integration.id}"
}

resource "aws_apigatewayv2_route" "post_options_notices" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  route_key = "OPTIONS /notices"
  target = "integrations/${aws_apigatewayv2_integration.api_gateway_integration.id}"
}

resource "aws_apigatewayv2_route" "delete_options_notice" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  route_key = "OPTIONS /notices/{id}"
  target = "integrations/${aws_apigatewayv2_integration.api_gateway_integration.id}"
}



resource "aws_apigatewayv2_stage" "stage" {
  #   - name = "$default", auto_deploy = true
  name= "$default"
  auto_deploy = true
  api_id = aws_apigatewayv2_api.api_gateway.id

}


# aws_lambda_permission - who is allowed to invoke your Lambda in the first place
#   - allows apigateway.amazonaws.com to invoke the lambda function
resource "aws_lambda_permission" "lambda_permission" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

# aws_s3_bucket (bucket = local.name)
resource "aws_s3_bucket" "bucket" {
  bucket = local.name
}

# aws_s3_bucket_public_access_block
#   - all block_* = false (Tier 1) -> flip to true in Tier 3 once CloudFront is added
resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  bucket = aws_s3_bucket.bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# aws_s3_bucket_policy
#   - Principal "*", Action "s3:GetObject" (Tier 1) -> replace with CloudFront OAC policy in Tier 3
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
  
  depends_on = [aws_s3_bucket_public_access_block.bucket_public_access_block]
}

# aws_s3_bucket_website_configuration
#   - index_document { suffix = "index.html" }
resource "aws_s3_bucket_website_configuration" "bucket_website_configuration" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = "index.html"
  }
}

# ---------------------------------------------------------------------------
# TIER 3 TODOs (add once Tier 1 is verified working)
# ---------------------------------------------------------------------------

# aws_cloudfront_origin_access_control
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${local.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# aws_cloudfront_distribution
#   - origin points at the S3 bucket via OAC (not the website endpoint)
resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  default_root_object = "index.html"
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id = local.name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }
  default_cache_behavior {
    target_origin_id = local.name
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]

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
}



# ---------------------------------------------------------------------------
# TIER 4 TODOs (optional, do after Tiers 1-3 are live)
# ---------------------------------------------------------------------------

# TODO: aws_cloudwatch_log_group x2 (lambda, apigw access logs)
# TODO: aws_cloudwatch_metric_alarm x2 (lambda errors, apigw 5xx)
# TODO: aws_cloudwatch_dashboard

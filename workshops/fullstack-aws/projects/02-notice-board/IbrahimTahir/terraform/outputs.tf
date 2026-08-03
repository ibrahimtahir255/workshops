# output "api_url"
#   value = the invoke URL of the aws_apigatewayv2_stage
#   -> feed this into VITE_API_URL when building the frontend
output "api_url" {
    value = aws_apigatewayv2_stage.stage.invoke_url
}

# output "s3_bucket_name"
#   value = the aws_s3_bucket bucket name
#   -> used by `aws s3 sync` and by the S3_BUCKET GitHub secret
output "s3_bucket_name" {
    value = aws_s3_bucket.bucket.bucket
}

# output "s3_website_endpoint" (Tier 1 only)
#   value = the aws_s3_bucket_website_configuration website_endpoint
output "s3_website_endpoint" {
    value = aws_s3_bucket_website_configuration.bucket_website_configuration.website_endpoint
}

# TODO: output "cloudfront_domain_name" (Tier 3)
#   value = the aws_cloudfront_distribution domain_name

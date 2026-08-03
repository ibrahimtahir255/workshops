variable "student_name" {
  description = "Your name, lowercase-hyphenated (e.g. \"john-smith\"). Used to prefix every resource so students don't collide in the shared AWS account."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "mongo_host" {
  description = "Public/private IP or DNS name of the MongoDB EC2 instance from the Lambda-MongoDB-EC2 lab."
  type        = string
}

variable "mongo_port" {
  description = "MongoDB port."
  type        = string
  default     = "27017"
}

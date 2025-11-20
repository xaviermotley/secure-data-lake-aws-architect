# Main Terraform configuration for secure data lake AWS reference architecture.

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "secure-data-lake"
}

# VPC and networking
resource "aws_vpc" "data_lake" {
  cidr_block = "10.10.0.0/16"
  tags       = { Name = "${var.prefix}-vpc" }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.data_lake.id
  cidr_block        = cidrsubnet(aws_vpc.data_lake.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${var.prefix}-public-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.data_lake.id
  cidr_block        = cidrsubnet(aws_vpc.data_lake.cidr_block, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "${var.prefix}-private-${count.index}" }
}

data "aws_availability_zones" "available" {}

# S3 buckets for data zones
resource "aws_s3_bucket" "raw" {
  bucket = "${var.prefix}-raw"
  versioning { enabled = true }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
  lifecycle_rule {
    id      = "transition_to_ia"
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
  tags = { Zone = "raw" }
}

resource "aws_s3_bucket" "cleaned" {
  bucket = "${var.prefix}-cleaned"
  versioning { enabled = true }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
  tags = { Zone = "cleaned" }
}

resource "aws_s3_bucket" "curated" {
  bucket = "${var.prefix}-curated"
  versioning { enabled = true }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
  tags = { Zone = "curated" }
}

# IAM roles for data engineers and analysts
resource "aws_iam_role" "data_engineer" {
  name = "${var.prefix}-data-engineer"
  assume_role_policy = data.aws_iam_policy_document.data_engineer_assume.json
}

data "aws_iam_policy_document" "data_engineer_assume" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role_policy" "data_engineer_policy" {
  role   = aws_iam_role.data_engineer.id
  policy = data.aws_iam_policy_document.data_engineer_policy.json
}

data "aws_iam_policy_document" "data_engineer_policy" {
  statement {
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "glue:*"
    ]
    resources = [
      aws_s3_bucket.raw.arn,
      "${aws_s3_bucket.raw.arn}/*",
      aws_s3_bucket.cleaned.arn,
      "${aws_s3_bucket.cleaned.arn}/*",
      aws_s3_bucket.curated.arn,
      "${aws_s3_bucket.curated.arn}/*"
    ]
  }
}

resource "aws_iam_role" "data_analyst" {
  name = "${var.prefix}-data-analyst"
  assume_role_policy = data.aws_iam_policy_document.data_engineer_assume.json
}

resource "aws_iam_role_policy" "data_analyst_policy" {
  role   = aws_iam_role.data_analyst.id
  policy = data.aws_iam_policy_document.data_analyst_policy.json
}

data "aws_iam_policy_document" "data_analyst_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.curated.arn,
      "${aws_s3_bucket.curated.arn}/*"
    ]
  }
}

data "aws_caller_identity" "current" {}

# Centralized logging using CloudTrail
resource "aws_cloudtrail" "org_trail" {
  name                          = "${var.prefix}-org-trail"
  s3_bucket_name                = aws_s3_bucket.raw.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}

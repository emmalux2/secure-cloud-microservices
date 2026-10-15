terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

import {
  to = aws_cloudwatch_log_group.waf_log_group
  id = "aws-waf-logs-main"
}

import {
  to = module.eks.aws_cloudwatch_log_group.this[0]
  id = "/aws/eks/secure-cloud-cluster-v2/cluster"
}

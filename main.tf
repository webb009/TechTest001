provider "aws" {
    access_key                  = "test_credentials"
    secret_key                  = "test_credentials"
    region                      = var.aws_region
    skip_credentials_validation = true
}

# Main VPC
resource "aws_vpc" "vpc" {
    cidr_block                  = var.vpc_cidr
    enable_dns_hostnames        = true

    tags = {
        Name                    = "${var.environment}-vpc"
        Environment             = var.environment
    }
}



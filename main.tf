provider "aws" {
    access_key                  = "test_credentials"
    secret_key                  = "test_credentials"
    region                      = var.aws_region
    skip_credentials_validation = true
}

# VPC
resource "aws_vpc" "vpc" {
    cidr_block                  = var.vpc_cidr
    enable_dns_hostnames        = true

    tags = {
        Name                    = "${var.environment}-vpc"
        Environment             = var.environment
    }
}

# Subnets
# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
    vpc_id                      = aws_vpc.vpc.id
    tags = {
        Name                    = "${var.environment}-igw"
        Environemtn             = var.environment
    }
}

# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
        vpc                     = true
        #depends_on              = [aws_internet_gateway.id]
}

# NAT
resource "aws_nat_gateway" "nat" {
        allocation_id           = aws_eip.nat_eip.id
        subnet_id               = element(aws_subnet.public_subnet.*.id, 0)

        tags = {
            Name                = "nat"
            Environment         = "${var.environment}"
        }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
        vpc_id                  = aws_vpc.vpc.id
        count                   = length(var.public_subnets_cidr)
        cidr_block              = element(var.public_subnets_cidr, count.index)
        availability_zone       = element(var.availability_zones, count.index)
        map_public_ip_on_launch = true

        tags = {
            Name                = "$[var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
            Environment         = "${var.environment}"
        }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
        vpc_id                  = aws_vpc.vpc.id
        count                   = length(var.private_subnets_cidr)
        cidr_block              = element(var.private_subnets_cidr, count.index)
        availability_zone       = element(var.availability_zones, count.index)
        map_public_ip_on_launch = false

        tags = {
            Name                = "{var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
            Environment         = "${var.environment}"
        }
}



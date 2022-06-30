variable "aws_region" {
    description = "AWS Region to launch servers"
    default = "eu-west-2"
}

variable "aws_access_key" {
    description = "AWS User Access Key"
    default = "XXXXXXXXXXXXXXXXXX"
}

variable "aws_secret_key" {
    description = "AWS User Secret Key"
    default = "XXXXXXXXXXXXXXXXXX"
}

variable "environment" {
    description = "Test Environment"   
}

variable "vpc_cidr" {
    description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
    type = list
    description = "CIDR block for public subnet"
}

variable "private_subnets_cidr" {
    type = list
    description = "CIDR block for private subnet"
}

variable "availability_zones" {
    type = list
    description = "Availibility Zone that resources will be deployed in"
}

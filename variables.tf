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


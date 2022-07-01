## ################################# ##
##            Privider
## ################################# ##
provider "aws" {
    access_key                  = "test_credentials"
    secret_key                  = "test_credentials"
    region                      = var.aws_region
    skip_credentials_validation = true
}

## ################################# ##
##              VPC
## ################################# ##
resource "aws_vpc" "vpc" {
    cidr_block                  = var.vpc_cidr
    enable_dns_hostnames        = true

    tags = {
        Name                    = "${var.environment}-vpc"
        Environment             = var.environment
    }
}

## ################################# ##
##            Subnets
## ################################# ##

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
        cidr_block              = "${var.public_subnets_cidr}"
        availability_zone       = "${var.availability_zones}"
        map_public_ip_on_launch = true

        tags = {
            Name                = "$[var.environment}-${var.availability_zones}-public-subnet"
            Environment         = "${var.environment}"
        }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
        vpc_id                  = aws_vpc.vpc.id
        count                   = length(var.private_subnets_cidr)
        cidr_block              = "${var.private_subnets_cidr}"
        availability_zone       = "${var.availability_zones}"
        map_public_ip_on_launch = false

        tags = {
            Name                = "{var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
            Environment         = "${var.environment}"
        }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "rds" {
        name                    = "${var.environment}-rds"
        description             = "Subnet Group for RDS"
        subnet_ids              = ["${aws_subnet.private_subnet.*.id}"]
}

## ################################# ##
##           Routing
## ################################# ##

# Routing Table for Public Subnet
resource "aws_route_table" "public" {
        vpc_id                  = aws_vpc.vpc.id
        tags = {
            Name                = "${var.environment}-public-route-table"
            Environment         = "${var.environment}"
        }
}

# Routing table for Private Subnet
resource "aws_route_table" "private" {
        vpc_id                  = aws_vpc.vpc.id
        tags = {
            Name                = "${var.environment}-private-route-table"
            Environment         = "$(var.environment}"
        }
}

# Routing for Internet Gateway
resource "aws_route" "public_internet_gateway" {
        route_table_id          = aws_route_table.public.id
        destination_cidr_block  = "0.0.0.0/0"
        gateway_id              = aws_internet_gateway.internet_gateway.id
}

# Routing for NAT
resource "aws_route" "private_nat_gateway" {
        route_table_id          = aws_route_table.private.id
        destination_cidr_block  = "0.0.0.0/0"
        nat_gateway_id          = aws_nat_gateway.nat.id
}

# Route table assosiation

# Route table association for public subnet
resource "aws_route_table_association" "public" {
        count                   = length(var.public_subnets_cidr)
        subnet_id               = element(aws_subnet.public_subnet.*.id, count.index)
        route_table_id          = aws_route_table.public.id
}

# Route table association for private subnet
resource "aws_route_table_association" "private" {
        count                   = length(var.private_subnets_cidr)
        subnet_id               = element(aws_subnet.private_subnet.*.id, count.index)
        route_table_id          = aws_route_table.private.id
}


resource "aws_key_pair" "aws-key" {
        key_name                = "aws-key"
        public_key              = file(var.public_key_path)
}
## ################################# ##
##         Security Groups
## ################################# ##

# Default Security Group for VPC
resource "aws_security_group" "default" {
        name                    = "${var.environment}-default-security-group"
        description             = "Default security group to allow traffic from VPC"
        vpc_id                  = aws_vpc.vpc.id
        depends_on = [
            aws_vpc.vpc
        ]

        ingress {
            from_port           = "0"
            to_port             = "0"
            protocol            = "-1"
            self                = true  
        }
           
        egress {
            from_port           = "0"
            to_port             = "0"
            protocol            = "-1"
            self                = "true"
        }

        tags = {
            Name                = "${var.environment}-default-security-group"
            Environment         = "${var.environment}"
        }
}

# RDS Security Group
resource "aws_security_group" "rds" {
        name                    = "${var.environment}-rds-security-group"
        description             = "RDS Mysql security group"
        vpc_id                  = aws_vpc.vpc.id

        ingress {
            from_port           = 3306
            to_port             = 3306
            protocol            = "tcp"
            security_groups     = ["${aws_security_group.default.id}"]
        }
        
        egress {
            from_port           = 0
            to_port             = 0
            protocol            = "tcp"
            cidr_blocks         = ["0.0.0.0/0"]
        }

        tags = {
            Name                = "${var.environment}-rds-security-group"
            Environment         = "${var.environment}"
        }
}

# Nginx Security Group
resource "aws_security_group" "allow-ssh" {
        vpc_id                  = aws_vpc.vpc.id
        ingress {
            from_port           = 22
            to_port             = 22
            protocol            = "tcp"
            # Restrict CIDR Block once known
            cidr_blocks         = ["0.0.0.0/0"]
        }
        ingress {
            from_port           = 80
            to_port             = 80
            protocol            = "tcp"
            # Restrict CIDR Block once known
            cidr_blocks         = ["0.0.0.0/0"] 
        }
        egress {
            from_port           = 0
            to_port             = 0
            protocol            = -1
            cidr_blocks         = ["0.0.0.0/0"]  
        }
        
        
}

## ################################# ##
##     Create RDS Instance
## ################################# ##
resource "aws_db_instance" "rds" {
        identifier              = "${var.environment}-${var.rds_instance_identifier}"
        allocated_storage       = 5
        engine                  = "mysql"
        engine_version          = "5.6.35"
        instance_class          = "db.t2.micro"
        name                    = "${var.environment}-${var.database_name}"
        username                = "${var.database_username}"
        password                = "${var.database_password}"
        db_subnet_group_name    = "${aws_db_subnet_group.rds.id}"
        vpc_security_group_ids  = ["${aws_security_group.rds.id}"]
        skip_final_snapshot     = true
        final_snapshot_identifier = "Ignore"
}


## ################################# ##
##     Create Nginx Instance
## ################################# ##
resource "aws_instance" "nginx_server" {
        ami                     = "ami-08d70e59c07c61a3a"
        instance_type           = "t2.micro"
        subnet_id               = aws_subnet.public_subnet.id
        vpc_security_group_ids      = ["${aws_security_group.allow-ssh.id}"]
        key_name                = aws_key_pair.aws-key.id

        # Store nginx.sh in EC2 instalnce
        provisioner "file" {
            source              = "nginx.sh"
            destination         = "/tmp/nginx.sh"
        }

        # Install nginx
        provisioner "remote-exec" {
            inline = [
                "chmod +x /tmp/nginx.sh",
                "sudo /tmp/nginx.sh"
            ]
        }

        # Setup SSH connection to nginx
        connection {
            type                = "ssh"
            host                = self.public_ip
            user                = "ubuntu"
            private_key          = file("${var.private_key_path}")
        }
        tags = {
            Name                = "${var.environment}-nginx"
            Environment         = "${var.environment}"
        }
}

## ################################# ##
##     Create ELB Instance
## ################################# ##

# Launch Config
resource "aws_launch_configuration" "elb_launch" {
  image_id               = ""
  instance_type          = "t2.micro"
  security_groups        = ["${aws_security_group.allow-ssh.id}"]
  key_name               = "${var.public_key_path}"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

## Create AutoScaling Group
resource "aws_autoscaling_group" "autoscale" {
        launch_configuration    = "${aws_launch_configuration.elb_launch.id}"
        availability_zones      = "${var.availability_zones}"
        min_size                = 2
        max_size                = 10
        load_balancers          = ["${aws_elb.nginx_elb.name}"]
        health_check_type       = "ELB"
}

## Create ELB
resource "aws_elb" "nginx_elb" {
        name                    = "${var.environment}-elb"
        security_groups         = ["${aws_security_group.allow-ssh.id}"]
        availability_zones      = "${var.availability_zones}"
        health_check {
            healthy_threshold = 2
            unhealthy_threshold = 2
            timeout = 3
            interval = 30
            target = "HTTP:8080/"
        }
        listener {
            lb_port = 80
            lb_protocol = "http"
            instance_port = "8080"
            instance_protocol = "http"
        }

        tags = {
            Name                = "${var.environment}-elb"
            Environment         = "${var.environment}"
        }
}

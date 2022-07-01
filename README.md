# TechTest001

This Test has been completed locally without any actual AWS access using terraform validate.


# Design

The intended design is to have a public and private subnet within a single VPC. The public subnet will hold the ELB and EC2 instance running the web server. The private subnet will hold the RDS instance. A NAT gateway will ensure that the EC2 instance can communicate with the RDS instance while rejecting traffic from external sources. 

      

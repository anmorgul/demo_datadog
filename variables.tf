variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "instance_type" {
  type        = string
  description = "Type of instance"
  default     = "t2.micro"
}

variable "app_name" {
  type    = string
  default = "testdatadog"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_a_cidr_block" {
  type    = string
  default = "10.20.0.0/24"
}

variable "availability_zone_a" {
  type    = string
  default = "eu-central-1a"
}

variable "key_name" {
  type = string
  default = "ubuntu"
}

variable "key_path" {
  type    = string
  default = "../secrets/ubuntu/id_rsa"
}

variable "ingress_web" {
  type = map(any)
  default = {
    "80" = {
      port_from   = 80,
      port_to     = 80,
      cidr_blocks = ["0.0.0.0/0"],
    }
    "8080" = {
      port_from   = 8080,
      port_to     = 8080,
      cidr_blocks = ["0.0.0.0/0"],
    }
  }
}

variable  "datadog_envs" {}

variable "shared_secret" {
 type = string
 default = "SOOPERSEKRET"
}

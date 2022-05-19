terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"

  cloud {
    organization = "Mendy-Terraform-Labs"

    workspaces {
      name = "terrform"
    }
  }

}


resource "random_id" "random_id_prefix" {
  byte_length = 2
}

locals {
  production_availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

module "Networking" {
  source               = "./modules/networking"
  region               = var.region
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  availability_zones   = local.production_availability_zones
}

resource "aws_key_pair" "aws_key" {
  key_name   = "aws_key"
  public_key = file("./aws_key.pub")
}

resource "aws_instance" "ec2_public" {
  ami                         = "ami-0f095f89ae15be883"
  instance_type               = "t2.small"
  key_name                    = "aws_key"
  security_groups             = module.Networking.security_groups_ids
  subnet_id                   =flatten( module.Networking.public_subnets_id)[0]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "EC2-PUBLIC"
  }
  # Copies the ssh key file to home dir
  provisioner "remote-exec" {
    inline = [
      "touch hello.txt",
      "echo helloworld remote provisioner >> hello.txt",
    ]
  }


  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("./aws_key")
    timeout     = "4m"
  }
}



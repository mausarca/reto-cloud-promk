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
  region = var.aws_region
}

# Lógica de nomenclatura automatizada
locals {
  suffix = "${var.proyecto}-${var.operacion}-01-${var.aws_region}"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}


module "network" {
  source = "./assets/networks"
}

module "compute" {
  source = "./assets/compute"
  subnet_id = module.network.subnet1_id
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.61.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
  required_version = ">= 1.4.5"
}


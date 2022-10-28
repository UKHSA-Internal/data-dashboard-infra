terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      Version = "~>3.27"
    }
  }

  required_version = ">=0.14.9"

}

provider "aws" {
  version = "~>3.0"
  region  = "eu-west-2"
}

required_version = ">=0.14.9" 

   backend "s3" {
       bucket = "ukhsa-dashboard-terra-backend"
       key    = "wl-backend-s3"
       region = "eu-west-2"
   }
}

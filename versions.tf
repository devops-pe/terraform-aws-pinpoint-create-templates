terraform {
  required_version = ">= 1.0.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
  }
}

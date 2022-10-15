terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.26"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.1"
    }
  }
}

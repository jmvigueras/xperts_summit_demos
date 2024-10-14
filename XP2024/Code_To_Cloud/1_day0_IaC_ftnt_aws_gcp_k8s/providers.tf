#--------------------------------------------------------------------------
# Terraform providers
#--------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}
provider "google" {
  project = var.project
  region  = local.gcp_region["id"]
  zone    = local.gcp_region["zone1"]
  //access_token = var.token
}
provider "google-beta" {
  project = var.project
  region  = local.gcp_region["id"]
  zone    = local.gcp_region["zone1"]
  //  access_token = var.token
}
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = local.aws_region["id"]
}
##############################################################################################################
# Providers variables
############################################################################################################### 
// AWS configuration
variable "access_key" {}
variable "secret_key" {}
// GCP configuration
variable "project" {}
//variable "token" {}

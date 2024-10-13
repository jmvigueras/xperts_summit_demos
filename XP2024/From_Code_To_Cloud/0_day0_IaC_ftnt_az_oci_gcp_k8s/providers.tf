#--------------------------------------------------------------------------
# Terraform providers
#--------------------------------------------------------------------------
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    oci = {
      source  = "hashicorp/oci"
      version = "~> 5.0"
    }
  }
}
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}
provider "google" {
  project = var.project
  region  = local.gcp_region["id"]
  zone    = local.gcp_region["zone1"]
  //  access_token = var.token
}
provider "google-beta" {
  project = var.project
  region  = local.gcp_region["id"]
  zone    = local.gcp_region["zone1"]
  //  access_token = var.token
}
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = local.oci_region
}

##############################################################################################################
# Providers variables
############################################################################################################### 
// Azure configuration
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
// GCP configuration
variable "project" {}
//variable "token" {}
// OCI configuration
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}

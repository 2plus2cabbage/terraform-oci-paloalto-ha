# Defines the Terraform provider and version requirements for the OCI deployment
terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"  # Specifies the OCI provider source
      version = ">= 5.38.0"      # Ensures a compatible provider version
    }
  }
}
# Configures the OCI provider with authentication details for Terraform to manage OCI resources
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid      # OCI tenancy ID for authentication
  user_ocid        = var.user_ocid         # OCI user ID for authentication
  fingerprint      = var.fingerprint       # Fingerprint of the API key for authentication
  private_key_path = var.private_key_path  # Path to the private key file for authentication
  region           = var.region            # OCI region where resources will be deployed
}
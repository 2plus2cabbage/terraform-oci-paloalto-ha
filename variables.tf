variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "compartment_name" {
  description = "The name of the compartment"
  type        = string
  default     = "Cabbage"
}

# Other existing variables...
variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the public key"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key for instance access"
  type        = string
}

variable "region" {
  description = "The OCI region"
  type        = string
}

variable "environment_name" {
  description = "The environment name for naming resources"
  type        = string
}

variable "location" {
  description = "The location for naming resources"
  type        = string
}

variable "firewall_image_ocid" {
  description = "The OCID of the firewall image"
  type        = string
}

variable "windows_image_ocid" {
  description = "The OCID of the Windows Server image"
  type        = string
}

variable "my_public_ip" {
  description = "Your public IP address for security list rules (format: x.x.x.x/32)"
  type        = string
}
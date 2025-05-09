                                                                                  # Creates the VCN to host the firewall and Windows Server
resource "oci_core_vcn" "cabbage_vcn" {
  cidr_block                 = "10.1.0.0/16"                                      # CIDR block for the VCN
  compartment_id             = var.compartment_ocid                               # Compartment for the VCN
  display_name               = "${local.vcn_name_prefix}-001"                     # Name of the VCN using local prefix
}

                                                                                  # Creates an internet gateway for internet-facing traffic
resource "oci_core_internet_gateway" "cabbage_igw" {
  compartment_id             = var.compartment_ocid                               # Compartment for the internet gateway
  vcn_id                     = oci_core_vcn.cabbage_vcn.id                        # VCN ID for the internet gateway
  display_name               = "${local.vcn_name_prefix}-001"                     # Name of the internet gateway using local prefix
}

                                                                                  # Creates the default route table for the VCN with a route to the internet gateway
resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.cabbage_vcn.default_route_table_id    # Default route table ID for the VCN
  route_rules {
    network_entity_id        = oci_core_internet_gateway.cabbage_igw.id           # Route to internet gateway
    destination              = "0.0.0.0/0"                                        # Route all traffic
    destination_type         = "CIDR_BLOCK"                                       # Destination type
  }
}

                                                                                  # Creates a subnet for the management interface of the firewall
resource "oci_core_subnet" "mgmt_subnet" {
  cidr_block                 = "10.1.0.0/24"                                      # CIDR block for the management subnet
  compartment_id             = var.compartment_ocid                               # Compartment for the subnet
  vcn_id                     = oci_core_vcn.cabbage_vcn.id                        # VCN ID for the subnet
  display_name               = "${local.mgmt_subnet_name_prefix}-001"             # Name of the management subnet using local prefix
  security_list_ids          = [oci_core_security_list.mgmt_security_list.id]     # Security list for the subnet
}

                                                                                  # Creates a subnet for the untrust interface of the firewall
resource "oci_core_subnet" "untrust_subnet" {
  cidr_block                 = "10.1.1.0/24"                                      # CIDR block for the untrust subnet
  compartment_id             = var.compartment_ocid                               # Compartment for the subnet
  vcn_id                     = oci_core_vcn.cabbage_vcn.id                        # VCN ID for the subnet
  display_name               = "${local.untrust_subnet_name_prefix}-001"          # Name of the untrust subnet using local prefix
  security_list_ids          = [oci_core_security_list.untrust_security_list.id]  # Security list for the subnet
}

                                                                                  # Creates a subnet for the trust interface of the firewall
resource "oci_core_subnet" "trust_subnet" {
  cidr_block                 = "10.1.2.0/24"                                      # CIDR block for the trust subnet
  compartment_id             = var.compartment_ocid                               # Compartment for the subnet
  vcn_id                     = oci_core_vcn.cabbage_vcn.id                        # VCN ID for the subnet
  display_name               = "${local.trust_subnet_name_prefix}-001"            # Name of the trust subnet using local prefix
  security_list_ids          = [oci_core_security_list.trust_security_list.id]    # Security list for the subnet
}

                                                                                  # Creates a subnet for the HA1 and HA2 interfaces of the firewalls
resource "oci_core_subnet" "ha_subnet" {
  cidr_block                 = "10.1.3.0/24"                                      # CIDR block for the HA1 and HA2 subnet
  compartment_id             = var.compartment_ocid                               # Compartment for the subnet
  vcn_id                     = oci_core_vcn.cabbage_vcn.id                        # VCN ID for the subnet
  display_name               = "${local.ha_subnet_name_prefix}-001"               # Name of the HA subnet using local prefix
  security_list_ids          = [oci_core_security_list.ha_security_list.id]       # Security list for the subnet
}
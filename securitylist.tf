                                                                       # Creates a security list for the trust subnet with permissive rules (firewall-controlled)
resource "oci_core_security_list" "trust_security_list" {
  compartment_id = var.compartment_ocid                                # Compartment for the security list
  vcn_id         = oci_core_vcn.cabbage_vcn.id                         # VCN ID for the security list
  display_name   = "${local.security_list_name_prefix}-trust-001"      # Name of the security list using local prefix

  ingress_security_rules {
    protocol     = "all"                                               # All protocols
    source       = "0.0.0.0/0"                                         # All sources
    description  = "Allow all inbound traffic (firewall-controlled)"
  }

  egress_security_rules {
    protocol     = "all"                                               # All protocols
    destination  = "0.0.0.0/0"                                         # All destinations
    description  = "Allow all outbound traffic"
  }
}

                                                                       # Creates a security list for the untrust subnet with permissive rules (firewall-controlled)
resource "oci_core_security_list" "untrust_security_list" {
  compartment_id = var.compartment_ocid                                # Compartment for the security list
  vcn_id         = oci_core_vcn.cabbage_vcn.id                         # VCN ID for the security list
  display_name   = "${local.security_list_name_prefix}-untrust-001"    # Name of the security list using local prefix

  ingress_security_rules {
    protocol     = "all"                                               # All protocols
    source       = "0.0.0.0/0"                                         # All sources
    description  = "Allow all inbound traffic (firewall-controlled)"
  }

  egress_security_rules {
    protocol     = "all"                                               # All protocols
    destination  = "0.0.0.0/0"                                         # All destinations
    description  = "Allow all outbound traffic"
  }
}

                                                                       # Creates a security list for the management subnet with rules for SSH and HTTPS
resource "oci_core_security_list" "mgmt_security_list" {
  compartment_id = var.compartment_ocid                                # Compartment for the security list
  vcn_id         = oci_core_vcn.cabbage_vcn.id                         # VCN ID for the security list
  display_name   = "${local.security_list_name_prefix}-mgmt-001"       # Name of the security list using local prefix

  ingress_security_rules {
    protocol     = "6"                                                 # TCP
    source       = var.my_public_ip                                    # Source IP for SSH
    description  = "Allow SSH from my public IP"
    tcp_options {
      min        = 22                                                  # SSH port
      max        = 22
    }
  }

  ingress_security_rules {
    protocol     = "6"                                                 # TCP
    source       = var.my_public_ip                                    # Source IP for HTTPS
    description  = "Allow HTTPS from my public IP"
    tcp_options {
      min        = 443                                                 # HTTPS port
      max        = 443
    }
  }

  egress_security_rules {
    protocol     = "all"                                               # All protocols
    destination  = "0.0.0.0/0"                                         # All destinations
    description  = "Allow all outbound traffic"
  }
}

                                                                       # Creates a security list for the HA subnet to allow all traffic within the subnet
resource "oci_core_security_list" "ha_security_list" {
  compartment_id = var.compartment_ocid                                # Compartment for the security list
  vcn_id         = oci_core_vcn.cabbage_vcn.id                         # VCN ID for the security list
  display_name   = "${local.security_list_name_prefix}-ha-001"         # Name of the security list using local prefix

  ingress_security_rules {
    protocol     = "all"                                               # All protocols
    source       = "10.1.3.0/24"                                       # HA subnet CIDR
    description  = "Allow all traffic within HA subnet"
  }

  egress_security_rules {
    protocol     = "all"                                               # All protocols
    destination  = "10.1.3.0/24"                                       # HA subnet CIDR
    description  = "Allow all outbound traffic"
  }
}
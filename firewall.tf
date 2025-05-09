                                                                                                                                                                                      # Creates a reserved public IP for Firewall A's untrust secondary IP
resource "oci_core_public_ip" "untrust_reserved_public_ip_a" {
  compartment_id           = var.compartment_ocid                                                                                                                                     # Compartment for the public IP
  lifetime                 = "RESERVED"                                                                                                                                               # Reserved public IP (persistent)
  display_name             = "${local.untrust_public_ip_name_prefix}-001"                                                                                                             # Name of the reserved public IP
  private_ip_id            = oci_core_private_ip.untrust_secondary_ip_a.id                                                                                                            # Associate with the secondary private IP
}

                                                                                                                                                                                      # Creates the Palo Alto firewall instance (Firewall A) in AD-1
resource "oci_core_instance" "firewall_instance" {
  availability_domain      = "gIaz:US-ASHBURN-AD-1"                                                                                                                                   # AD-1 for Firewall A
  compartment_id           = var.compartment_ocid                                                                                                                                     # Compartment for the firewall
  shape                    = "VM.Optimized3.Flex"                                                                                                                                     # Shape for the firewall
  shape_config {
    ocpus                  = 4                                                                                                                                                        # 4 OCPUs to support 5 VNICs
    memory_in_gbs          = 16                                                                                                                                                       # 16 GB RAM
  }
  display_name             = "${local.firewall_name_prefix}-001"                                                                                                                      # Name of Firewall A instance
  source_details {
    source_type            = "image"                                                                                                                                                  # Source type for the firewall
    source_id              = var.firewall_image_ocid                                                                                                                                  # Firewall image OCID from Marketplace
  }
  create_vnic_details {
    subnet_id              = oci_core_subnet.mgmt_subnet.id                                                                                                                           # Primary VNIC in management subnet (VNIC0)
    display_name           = local.mgmt_vnic_name_prefix                                                                                                                              # Name of the primary VNIC
    assign_public_ip       = true                                                                                                                                                     # Assign an ephemeral public IP to management
    private_ip             = "10.1.0.10"                                                                                                                                              # Static IP for management (Firewall A)
  }
  metadata                 = {
    ssh_authorized_keys    = var.ssh_public_key                                                                                                                                       # SSH public key for admin user login
  }
}

                                                                                                                                                                                      # Creates the second Palo Alto firewall instance (Firewall B) in AD-2
resource "oci_core_instance" "firewall_instance_b" {
  availability_domain      = "gIaz:US-ASHBURN-AD-2"                                                                                                                                   # AD-2 for Firewall B
  compartment_id           = var.compartment_ocid                                                                                                                                     # Compartment for the firewall
  shape                    = "VM.Optimized3.Flex"                                                                                                                                     # Shape for the firewall
  shape_config {
    ocpus                  = 4                                                                                                                                                        # 4 OCPUs to support 5 VNICs
    memory_in_gbs          = 16                                                                                                                                                       # 16 GB RAM
  }
  display_name             = "${local.firewall_name_prefix}-002"                                                                                                                      # Name of Firewall B instance
  source_details {
    source_type            = "image"                                                                                                                                                  # Source type for the firewall
    source_id              = var.firewall_image_ocid                                                                                                                                  # Firewall image OCID from Marketplace
  }
  create_vnic_details {
    subnet_id              = oci_core_subnet.mgmt_subnet.id                                                                                                                           # Primary VNIC in management subnet (VNIC0)
    display_name           = "${local.mgmt_vnic_name_prefix}-b"                                                                                                                       # Name of the primary VNIC for Firewall B
    assign_public_ip       = true                                                                                                                                                     # Assign an ephemeral public IP to management
    private_ip             = "10.1.0.11"                                                                                                                                              # Static IP for management (Firewall B)
  }
  metadata                 = {
    ssh_authorized_keys    = var.ssh_public_key                                                                                                                                       # SSH public key for admin user login
  }
}

                                                                                                                                                                                      # Creates a VNIC for Firewall A's untrust interface
resource "oci_core_vnic_attachment" "untrust_vnic_attachment" {
  instance_id              = oci_core_instance.firewall_instance.id                                                                                                                   # Firewall A instance ID
  display_name             = local.untrust_vnic_name_prefix                                                                                                                           # Name of the untrust VNIC
  create_vnic_details {
    subnet_id              = oci_core_subnet.untrust_subnet.id                                                                                                                        # Untrust subnet ID
    display_name           = local.untrust_vnic_name_prefix                                                                                                                           # Name of the untrust VNIC
    assign_public_ip       = false                                                                                                                                                    # No public IP (handled by secondary IP)
    private_ip             = "10.1.1.10"                                                                                                                                              # Static IP for untrust interface (Firewall A)
    skip_source_dest_check = true                                                                                                                                                     # Disable src/dst check for untrust
  }
}

                                                                                                                                                                                      # Assigns a secondary private IP to Firewall A's untrust VNIC
resource "oci_core_private_ip" "untrust_secondary_ip_a" {
  vnic_id                  = oci_core_vnic_attachment.untrust_vnic_attachment.vnic_id                                                                                                 # Untrust VNIC ID for Firewall A
  display_name             = "${local.untrust_vnic_name_prefix}-secondary"                                                                                                            # Name of the secondary IP
  ip_address               = "10.1.1.110"                                                                                                                                             # Secondary IP for untrust interface (Firewall A)
}

                                                                                                                                                                                      # Creates a VNIC for Firewall B's untrust interface
resource "oci_core_vnic_attachment" "untrust_vnic_attachment_b" {
  instance_id              = oci_core_instance.firewall_instance_b.id                                                                                                                 # Firewall B instance ID
  display_name             = "${local.untrust_vnic_name_prefix}-b"                                                                                                                    # Name of the untrust VNIC for Firewall B
  create_vnic_details {
    subnet_id              = oci_core_subnet.untrust_subnet.id                                                                                                                        # Untrust subnet ID
    display_name           = "${local.untrust_vnic_name_prefix}-b"                                                                                                                    # Name of the untrust VNIC
    assign_public_ip       = false                                                                                                                                                    # No public IP
    private_ip             = "10.1.1.11"                                                                                                                                              # Static IP for untrust interface (Firewall B)
    skip_source_dest_check = true                                                                                                                                                     # Disable src/dst check for untrust
  }
}

                                                                                                                                                                                      # Creates a VNIC for Firewall A's trust interface
resource "oci_core_vnic_attachment" "trust_vnic_attachment" {
  instance_id              = oci_core_instance.firewall_instance.id                                                                                                                   # Firewall A instance ID
  display_name             = local.trust_vnic_name_prefix                                                                                                                             # Name of the trust VNIC
  depends_on               = [oci_core_vnic_attachment.untrust_vnic_attachment]                                                                                                       # Ensure untrust VNIC attaches first
  create_vnic_details {
    subnet_id              = oci_core_subnet.trust_subnet.id                                                                                                                          # Trust subnet ID
    display_name           = local.trust_vnic_name_prefix                                                                                                                             # Name of the trust VNIC
    assign_public_ip       = false                                                                                                                                                    # No public IP for trust VNIC
    private_ip             = "10.1.2.10"                                                                                                                                              # Static IP for trust interface (Firewall A)
    skip_source_dest_check = true                                                                                                                                                     # Disable src/dst check for trust
  }
}

                                                                                                                                                                                      # Assigns a secondary private IP to Firewall A's trust VNIC (no public IP)
resource "oci_core_private_ip" "trust_secondary_ip_a" {
  vnic_id                  = oci_core_vnic_attachment.trust_vnic_attachment.vnic_id                                                                                                   # Trust VNIC ID for Firewall A
  display_name             = "${local.trust_vnic_name_prefix}-secondary"                                                                                                              # Name of the secondary IP
  ip_address               = "10.1.2.110"                                                                                                                                             # Secondary IP for trust interface (Firewall A)
}

                                                                                                                                                                                      # Creates a VNIC for Firewall B's trust interface
resource "oci_core_vnic_attachment" "trust_vnic_attachment_b" {
  instance_id              = oci_core_instance.firewall_instance_b.id                                                                                                                 # Firewall B instance ID
  display_name             = "${local.trust_vnic_name_prefix}-b"                                                                                                                      # Name of the trust VNIC for Firewall B
  depends_on               = [oci_core_vnic_attachment.untrust_vnic_attachment_b]                                                                                                     # Ensure untrust VNIC attaches first
  create_vnic_details {
    subnet_id              = oci_core_subnet.trust_subnet.id                                                                                                                          # Trust subnet ID
    display_name           = "${local.trust_vnic_name_prefix}-b"                                                                                                                      # Name of the trust VNIC
    assign_public_ip       = false                                                                                                                                                    # No public IP for trust VNIC
    private_ip             = "10.1.2.11"                                                                                                                                              # Static IP for trust interface (Firewall B)
    skip_source_dest_check = true                                                                                                                                                     # Disable src/dst check for trust
  }
}

                                                                                                                                                                                      # Creates a VNIC for Firewall A's HA1 interface
resource "oci_core_vnic_attachment" "ha1_vnic_attachment" {
  instance_id              = oci_core_instance.firewall_instance.id                                                                                                                   # Firewall A instance ID
  display_name             = local.ha1_vnic_name_prefix                                                                                                                               # Name of the HA1 VNIC using updated prefix
  depends_on               = [oci_core_vnic_attachment.trust_vnic_attachment]                                                                                                         # Ensure trust VNIC attaches first
  create_vnic_details {
    subnet_id              = oci_core_subnet.ha_subnet.id                                                                                                                             # HA subnet ID
    display_name           = local.ha1_vnic_name_prefix                                                                                                                               # Name of the HA1 VNIC
    assign_public_ip       = false                                                                                                                                                    # No public IP for HA1 VNIC
    private_ip             = "10.1.3.10"                                                                                                                                              # Static IP for HA1 interface (Firewall A)
  }
}

                                                                                                                                                                                      # Creates a VNIC for Firewall B's HA1 interface
resource "oci_core_vnic_attachment" "ha1_vnic_attachment_b" {
  instance_id              = oci_core_instance.firewall_instance_b.id                                                                                                                 # Firewall B instance ID
  display_name             = "${local.ha1_vnic_name_prefix}-b"                                                                                                                        # Name of the HA1 VNIC for Firewall B using updated prefix
  depends_on               = [oci_core_vnic_attachment.trust_vnic_attachment_b]                                                                                                       # Ensure trust VNIC attaches first
  create_vnic_details {
    subnet_id              = oci_core_subnet.ha_subnet.id                                                                                                                             # HA subnet ID
    display_name           = "${local.ha1_vnic_name_prefix}-b"                                                                                                                        # Name of the HA1 VNIC
    assign_public_ip       = false                                                                                                                                                    # No public IP for HA1 VNIC
    private_ip             = "10.1.3.11"                                                                                                                                              # Static IP for HA1 interface (Firewall B)
  }
}

                                                                                                                                                                                      # Creates a VNIC for Firewall A's HA2 interface
resource "oci_core_vnic_attachment" "ha2_vnic_attachment" {
  instance_id              = oci_core_instance.firewall_instance.id                                                                                                                   # Firewall A instance ID
  display_name             = local.ha2_vnic_name_prefix                                                                                                                               # Name of the HA2 VNIC using updated prefix
  depends_on               = [oci_core_vnic_attachment.ha1_vnic_attachment]                                                                                                           # Ensure HA1 VNIC attaches first
  create_vnic_details {
    subnet_id              = oci_core_subnet.ha_subnet.id                                                                                                                             # HA subnet ID (same as HA1)
    display_name           = local.ha2_vnic_name_prefix                                                                                                                               # Name of the HA2 VNIC
    assign_public_ip       = false                                                                                                                                                    # No public IP for HA2 VNIC
    private_ip             = "10.1.3.110"                                                                                                                                             # Static IP for HA2 interface (Firewall A)
  }
}

                                                                                                                                                                                      # Creates a VNIC for Firewall B's HA2 interface
resource "oci_core_vnic_attachment" "ha2_vnic_attachment_b" {
  instance_id              = oci_core_instance.firewall_instance_b.id                                                                                                                 # Firewall B instance ID
  display_name             = "${local.ha2_vnic_name_prefix}-b"                                                                                                                        # Name of the HA2 VNIC for Firewall B using updated prefix
  depends_on               = [oci_core_vnic_attachment.ha1_vnic_attachment_b]                                                                                                         # Ensure HA1 VNIC attaches first
  create_vnic_details {
    subnet_id              = oci_core_subnet.ha_subnet.id                                                                                                                             # HA subnet ID (same as HA1)
    display_name           = "${local.ha2_vnic_name_prefix}-b"                                                                                                                        # Name of the HA2 VNIC
    assign_public_ip       = false                                                                                                                                                    # No public IP for HA2 VNIC
    private_ip             = "10.1.3.111"                                                                                                                                             # Static IP for HA2 interface (Firewall B)
  }
}

                                                                                                                                                                                      # Fetches the VNIC details for Firewall A's trust interface
data "oci_core_vnic" "trust_vnic" {
  vnic_id                  = oci_core_vnic_attachment.trust_vnic_attachment.vnic_id                                                                                                   # Trust VNIC ID for Firewall A
}

                                                                                                                                                                                      # Fetches the VNIC details for Firewall B's trust interface
data "oci_core_vnic" "trust_vnic_b" {
  vnic_id                  = oci_core_vnic_attachment.trust_vnic_attachment_b.vnic_id                                                                                                 # Trust VNIC ID for Firewall B
}

                                                                                                                                                                                      # Fetches the VNIC details for Firewall A's untrust interface
data "oci_core_vnic" "untrust_vnic" {
  vnic_id                  = oci_core_vnic_attachment.untrust_vnic_attachment.vnic_id                                                                                                 # Untrust VNIC ID for Firewall A
}

                                                                                                                                                                                      # Fetches the VNIC details for Firewall B's untrust interface
data "oci_core_vnic" "untrust_vnic_b" {
  vnic_id                  = oci_core_vnic_attachment.untrust_vnic_attachment_b.vnic_id                                                                                               # Untrust VNIC ID for Firewall B
}

                                                                                                                                                                                      # Outputs the private IP of Firewall A's trust interface
output "firewall_trust_private_ip_a" {
  value                    = data.oci_core_vnic.trust_vnic.private_ip_address                                                                                                         # Private IP of the trust interface for Firewall A (10.1.2.10)
  description              = "Private IP of Firewall A's trust interface"
}

                                                                                                                                                                                      # Outputs the secondary IP of Firewall A's trust interface
output "firewall_trust_secondary_ip_a" {
  value                    = oci_core_private_ip.trust_secondary_ip_a.ip_address                                                                                                      # Secondary IP of the trust interface for Firewall A (10.1.2.110)
  description              = "Secondary IP of Firewall A's trust interface"
}

                                                                                                                                                                                      # Outputs the private IP of Firewall B's trust interface
output "firewall_trust_private_ip_b" {
  value                    = data.oci_core_vnic.trust_vnic_b.private_ip_address                                                                                                       # Private IP of the trust interface for Firewall B (10.1.2.11)
  description              = "Private IP of Firewall B's trust interface"
}

                                                                                                                                                                                      # Outputs the private IP of Firewall A's untrust interface
output "firewall_untrust_private_ip_a" {
  value                    = data.oci_core_vnic.untrust_vnic.private_ip_address                                                                                                       # Private IP of the untrust interface for Firewall A (10.1.1.10)
  description              = "Private IP of Firewall A's untrust interface"
}

                                                                                                                                                                                      # Outputs the private IP of Firewall B's untrust interface
output "firewall_untrust_private_ip_b" {
  value                    = data.oci_core_vnic.untrust_vnic_b.private_ip_address                                                                                                     # Private IP of the untrust interface for Firewall B (10.1.1.11)
  description              = "Private IP of Firewall B's untrust interface"
}

                                                                                                                                                                                      # Outputs the secondary IP of Firewall A's untrust interface
output "firewall_untrust_secondary_ip_a" {
  value                    = oci_core_private_ip.untrust_secondary_ip_a.ip_address                                                                                                    # Secondary IP of the untrust interface for Firewall A (10.1.1.110)
  description              = "Secondary IP of Firewall A's untrust interface"
}

                                                                                                                                                                                      # Outputs the reserved public IP for Firewall A's untrust secondary IP
output "firewall_untrust_secondary_reserved_public_ip_a" {
  value                    = oci_core_public_ip.untrust_reserved_public_ip_a.ip_address                                                                                               # Reserved public IP of the untrust secondary IP for Firewall A
  description              = "Reserved public IP for Firewall A's untrust secondary IP"
}

                                                                                                                                                                                      # Outputs the public IP of Firewall A's management interface (primary VNIC)
output "firewall_mgmt_public_ip_a" {
  value                    = oci_core_instance.firewall_instance.public_ip                                                                                                            # Public IP of the management interface for Firewall A
  description              = "Public IP of Firewall A's management interface"
}

                                                                                                                                                                                      # Outputs the public IP of Firewall B's management interface (primary VNIC)
output "firewall_mgmt_public_ip_b" {
  value                    = oci_core_instance.firewall_instance_b.public_ip                                                                                                          # Public IP of the management interface for Firewall B
  description              = "Public IP of Firewall B's management interface"
}

                                                                                                                                                                                      # Outputs the HA1 IP of Firewall A
output "firewall_ha1_ip_a" {
  value                    = "10.1.3.10"                                                                                                                                              # HA1 IP for Firewall A
  description              = "HA1 IP of Firewall A"
}

                                                                                                                                                                                      # Outputs the HA1 IP of Firewall B
output "firewall_ha1_ip_b" {
  value                    = "10.1.3.11"                                                                                                                                              # HA1 IP for Firewall B
  description              = "HA1 IP of Firewall B"
}

                                                                                                                                                                                      # Outputs the HA2 IP of Firewall A
output "firewall_ha2_ip_a" {
  value                    = "10.1.3.110"                                                                                                                                             # HA2 IP for Firewall A
  description              = "HA2 IP of Firewall A"
}

                                                                                                                                                                                      # Outputs the HA2 IP of Firewall B
output "firewall_ha2_ip_b" {
  value                    = "10.1.3.111"                                                                                                                                             # HA2 IP for Firewall B
  description              = "HA2 IP of Firewall B"
}

resource "oci_core_app_catalog_subscription" "generated_oci_core_app_catalog_subscription" {
  compartment_id           = var.compartment_ocid                                                                                                                                     # Compartment for the subscription
  eula_link                = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.eula_link}"                 # EULA link for the image
  listing_id               = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.listing_id}"                # Listing ID for the image
  listing_resource_version = "10.1.14-h9"                                                                                                                                             # Version of the image to subscribe to
  oracle_terms_of_use_link = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.oracle_terms_of_use_link}"  # Oracle terms of use link
  signature                = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.signature}"                 # Signature for the agreement
  time_retrieved           = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.time_retrieved}"            # Time the agreement was retrieved
}

resource "oci_core_app_catalog_listing_resource_version_agreement" "generated_oci_core_app_catalog_listing_resource_version_agreement" {
  listing_id               = "ocid1.appcataloglisting.oc1..aaaaaaaai7wszf2tvojm2zw5epmx6ynaivbbe6zpye2kts344zg6u2jujbta"                                                              # Listing ID for the Palo Alto image
  listing_resource_version = "10.1.14-h9"                                                                                                                                             # Version of the Palo Alto image
}
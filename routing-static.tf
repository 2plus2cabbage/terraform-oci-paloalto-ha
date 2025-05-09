                                                                                            # Fetches the private IPs for the trust interface of the active firewall (secondary IP, initially Firewall A)
data "oci_core_private_ips" "trust_private_ips" {
  subnet_id                = oci_core_subnet.trust_subnet.id                                # Trust subnet ID
  ip_address               = "10.1.2.110"                                                   # Firewall A's secondary trust IP
  depends_on               = [
    oci_core_vnic_attachment.trust_vnic_attachment,                                         # Ensure Firewall A's trust VNIC is created
    oci_core_private_ip.trust_secondary_ip_a                                                # Ensure Firewall A's secondary trust IP is created
  ]
}

                                                                                            # Creates a route table for the trust subnet with a route to the firewall
resource "oci_core_route_table" "trust_route_table" {
  compartment_id           = var.compartment_ocid                                           # Compartment for the route table
  vcn_id                   = oci_core_vcn.cabbage_vcn.id                                    # VCN ID for the route table
  display_name             = "${local.route_table_name_prefix}-trust-001"                   # Name of the trust route table
  route_rules {
    destination            = "0.0.0.0/0"                                                    # Route all traffic
    network_entity_id      = data.oci_core_private_ips.trust_private_ips.private_ips[0].id  # Route to firewall trust interface
    description            = "Route to firewall trust interface"                            # Description of the route rule
  }
}
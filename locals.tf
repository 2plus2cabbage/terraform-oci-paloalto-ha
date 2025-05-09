locals {
  vcn_name_prefix               = "vcn-${var.environment_name}-${var.location}"           # VCN name prefix
  trust_subnet_name_prefix      = "snet-${var.environment_name}-${var.location}-trust"    # Trust subnet name prefix
  untrust_subnet_name_prefix    = "snet-${var.environment_name}-${var.location}-untrust"  # Untrust subnet name prefix
  mgmt_subnet_name_prefix       = "snet-${var.environment_name}-${var.location}-mgmt"     # Management subnet name prefix
  ha_subnet_name_prefix         = "snet-${var.environment_name}-${var.location}-ha"       # HA subnet name prefix
  security_list_name_prefix     = "slist-${var.environment_name}-${var.location}"         # Security list name prefix
  route_table_name_prefix       = "rt-${var.environment_name}-${var.location}"            # Route table name prefix
  drg_name_prefix               = "drg-${var.environment_name}-${var.location}"           # DRG name prefix
  firewall_name_prefix          = "fw-${var.environment_name}-${var.location}"            # Firewall name prefix
  windows_name_prefix           = "vm-${var.environment_name}-${var.location}-windows"    # Windows Server name prefix
  trust_vnic_name_prefix        = "vnic-${var.environment_name}-${var.location}-trust"    # VNIC name prefix for the firewall trust interface
  untrust_vnic_name_prefix      = "vnic-${var.environment_name}-${var.location}-untrust"  # VNIC name prefix for the firewall untrust interface
  mgmt_vnic_name_prefix         = "vnic-${var.environment_name}-${var.location}-mgmt"     # VNIC name prefix for the firewall management interface
  ha1_vnic_name_prefix          = "vnic-${var.environment_name}-${var.location}-ha1"      # VNIC name prefix for the firewall HA1 interface
  ha2_vnic_name_prefix          = "vnic-${var.environment_name}-${var.location}-ha2"      # VNIC name prefix for the firewall HA2 interface
  untrust_public_ip_name_prefix = "pip-${var.environment_name}-${var.location}-untrust"   # Public IP name prefix for the firewall untrust interface
  mgmt_public_ip_name_prefix    = "pip-${var.environment_name}-${var.location}-mgmt"      # Public IP name prefix for the firewall management interface
}
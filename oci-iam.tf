                                                                                                                                                    # Creates a Dynamic Group for the HA firewalls
resource "oci_identity_dynamic_group" "ha_firewall_dynamic_group" {
  compartment_id  = var.tenancy_ocid                                                                                                                # Tenancy OCID for the Dynamic Group (Dynamic Groups are tenancy-level)
  name            = "HA-FIREWALL-GROUP"                                                                                                             # Name of the Dynamic Group without compartment prefix
  description     = "Dynamic group for HA firewalls to manage secondary IP movement"
  matching_rule   = "Any {instance.id = '${oci_core_instance.firewall_instance.id}', instance.id = '${oci_core_instance.firewall_instance_b.id}'}"  # Match Firewall A and B instance OCIDs
  depends_on      = [
    oci_core_instance.firewall_instance,                                                                                                            # Ensure Firewall A is created
    oci_core_instance.firewall_instance_b                                                                                                           # Ensure Firewall B is created
  ]
}

                                                                                                                                                    # Introduce a delay to ensure the dynamic group is fully propagated before the policy is applied
resource "time_sleep" "wait_for_dynamic_group_propagation" {
  depends_on      = [oci_identity_dynamic_group.ha_firewall_dynamic_group]
  create_duration = "60s"                                                                                                                           # Wait 60 seconds to allow OCI IAM to propagate the dynamic group
}

                                                                                                                                                    # Creates an IAM Policy for the HA firewalls in the root tenancy
resource "oci_identity_policy" "ha_firewall_policy" {
  compartment_id  = var.tenancy_ocid                                                                                                                # Root tenancy for the policy
  name            = "HA-Firewall-Policy"                                                                                                            # Name of the policy
  description     = "Policy for HA firewalls to manage VNICs and instances in the compartment"
  statements      = [
    "Allow dynamic-group HA-FIREWALL-GROUP to use virtual-network-family in tenancy",
    "Allow dynamic-group HA-FIREWALL-GROUP to use instance-family in tenancy",
  ]
  depends_on      = [time_sleep.wait_for_dynamic_group_propagation]                                                                                 # Ensure policy creation waits for the delay
}
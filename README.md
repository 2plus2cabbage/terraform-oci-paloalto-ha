<img align="right" width="150" src="https://github.com/2plus2cabbage/2plus2cabbage/blob/main/images/2plus2cabbage.png">

<img src="https://github.com/2plus2cabbage/2plus2cabbage/blob/main/images/oci-paloalto-ha.png" alt="oci-paloalto-ha" width="300" align="left">
<br clear="left">

# OCI High Availability Firewall and Windows Server Terraform Deployment

This project deploys two Palo Alto firewalls in a high availability (HA) configuration alongside a Windows Server 2022 instance in Oracle Cloud Infrastructure (OCI). Each firewall is equipped with five interfaces: management, untrust, trust, HA1, and HA2. The Windows Server resides in the trust subnet and accesses the internet through the active firewall.

## Files
The project is organized into multiple files to promote modularity, keeping distinct constructs separate for easier management and understanding:
- `ociprovider.tf`: Configures the OCI provider.
- `main.tf`: Defines Terraform provider requirements.
- `locals.tf`: Specifies naming prefixes for resources.
- `variables.tf`: Defines input variables.
- `terraform.tfvars`: Contains variable values (update with your details).
- `terraform.tfvars.template`: Template for variable values.
- `oci-networking.tf`: Sets up the VCN, subnets, and gateways.
- `routing-static.tf`: Configures the trust subnet route table.
- `securitylist.tf`: Defines security rules for subnets.
- `firewall.tf`: Deploys two Palo Alto firewalls (A and B) with management, untrust, trust, HA1, and HA2 interfaces.
- `windows.tf`: Deploys the Windows Server in the trust subnet.
- `oci-iam.tf`: Creates a Dynamic Group and IAM policies for HA failover.
- `firewall-configs\firewall-a-config.xml`: The configuration file for Firewall A.
- `firewall-configs\firewall-b-config.xml`: The configuration file for Firewall B.

## How It Works
- **Networking**: The VCN includes four subnets:
  - Management: `10.1.0.0/24`
  - Untrust: `10.1.1.0/24`
  - Trust: `10.1.2.0/24`
  - HA: `10.1.3.0/24`
  An internet gateway enables inbound and outbound traffic for the management and untrust subnets via the VCN’s default route table. The trust subnet uses a custom route table to direct traffic through the firewall’s secondary trust IP (`10.1.2.110`).
- **Security**: Security lists allow SSH/HTTPS to the firewall management interfaces from your IP, all inbound traffic to the untrust and trust interfaces (firewall-controlled), all traffic within the HA subnet, and all outbound traffic from the management and untrust subnets.
- **Firewalls**: Two firewalls configured for HA:
  - Firewall A: Management (`10.1.0.10`), Untrust (`10.1.1.10`, secondary `10.1.1.110`), Trust (`10.1.2.10`, secondary `10.1.2.110`), HA1 (`10.1.3.10`), HA2 (`10.1.3.110`).
  - Firewall B: Management (`10.1.0.11`), Untrust (`10.1.1.11`), Trust (`10.1.2.11`), HA1 (`10.1.3.11`), HA2 (`10.1.3.111`).
- **Instance**: A Windows Server 2022 VM in the trust subnet (`10.1.2.20`) with no public IP, and its firewall disabled via `user_data`.
- **HA Policies**: A Dynamic Group and IAM policy enable the firewalls to manage secondary IPs for failover.

## Prerequisites
- An OCI account with a compartment.
- An API key pair with noted `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`, and `region`.
- Terraform installed on your machine.
- Examples are demonstrated using Visual Studio Code (VSCode).
- An SSH key pair for firewall access.
- Palo Alto firewall image OCID from the OCI Marketplace.
- Your public IP address for security list rules.

## Deployment Steps
1. Clone the repository.
2. Copy `terraform.tfvars.template` to `terraform.tfvars` and update it with your OCI credentials, firewall image OCID, SSH public key, and your public IP in `my_public_ip`.
3. Run `terraform init`, then (optionally) `terraform plan` to preview changes, and then `terraform apply` (type `yes`).
4. Retrieve the management public IPs from the outputs: `firewall_mgmt_public_ip_a` (Firewall A) and `firewall_mgmt_public_ip_b` (Firewall B). Alternatively, run `terraform output` or check in the OCI Console under **Compute > Instances**.
5. SSH to Firewall A’s management interface using `ssh -i <private-key-file> admin@<firewall_mgmt_public_ip_a>`. Change the admin password for GUI access: enter configuration mode with `configure`, set the password with `set mgt-config users admin password`, commit with `commit`, and exit with `exit`. Repeat for Firewall B using `firewall_mgmt_public_ip_b`.
6. Update `MY-PUBLIC-IP` in both firewall configuration files (`firewall-configs\firewall-a-config.xml` and `firewall-configs\firewall-b-config.xml`): replace `5.5.5.5/32` with your actual public IP (same as `my_public_ip` in `terraform.tfvars`), then save the files.
7. Import the XML configuration to both firewalls via the GUI at `https://<firewall_mgmt_public_ip_a>` and `https://<firewall_mgmt_public_ip_b>`: log in with username `admin` and the password set in Step 5, go to **Device > Setup > Operations > Import Named Configuration Snapshot**, upload your XML file, then navigate to **Device > Setup > Operations > Load Named Configuration Snapshot**, select the uploaded file, and commit. Note that after the commit, the admin password will be changed to `2Plus2cabbage!`.
8. Configure the trust subnet to use the custom trust route table: In the OCI Console, go to **Networking > Virtual Cloud Networks > [your VCN] > Subnets > [trust subnet] > Edit**, set the route table to the trust route table (named with the prefix from `locals.tf` and suffix `-trust-001`), and save changes.
9. Access the Windows Server via RDP: Use the untrust secondary public IP (`firewall_untrust_secondary_reserved_public_ip_a`), port 3389, username `opc`, and initial password from the OCI Console (**Compute > Instances > [select Windows instance] > Resources > Instance Access > Show Initial Password**).
10. Verify connectivity from the Windows Server: Open Command Prompt or PowerShell, test internet access with `ping google.com`, and confirm connectivity is successful.
11. Initiate failover from Firewall A to Firewall B: Log in to Firewall A’s GUI at `https://<firewall_mgmt_public_ip_a>` using the updated admin credentials (`admin`/`2Plus2cabbage!`). Navigate to **Device > High Availability > Operational Commands**, click **Suspend local device** to trigger failover to Firewall B. Confirm that the RDP connection to the Windows Server remains uninterrupted.

## Clean Up Resources
1. Reset the trust subnet route table to default in the OCI Console: Navigate to **Networking > Virtual Cloud Networks > [your VCN] > Subnets > [trust subnet] > Edit**, set the route table to the VCN’s default route table, and save changes.
2. Run `terraform destroy` to remove all resources (type `yes`).

## Potential costs and licensing
- The resources deployed using this Terraform configuration should generally incur minimal to no costs, provided they are terminated promptly after creation.
- It is important to fully understand your cloud provider's billing structure, trial periods, and any potential costs associated with the deployment of resources in public cloud environments.
- You are also responsible for any applicable software licensing or other charges that may arise from the deployment and usage of these resources.
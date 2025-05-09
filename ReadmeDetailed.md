# Detailed Guide - OCI High Availability Firewall and Windows Server Terraform Deployment

This project deploys a high availability (HA) setup with two Palo Alto firewalls and a Windows Server 2022 instance in Oracle Cloud Infrastructure (OCI). The firewalls are configured in an active/passive HA pair, each with five interfaces - management, untrust, trust, HA1, and HA2. The Windows Server resides in the trust subnet and accesses the internet through the active firewall, ensuring secure and resilient connectivity.

## Project Overview
This Terraform deployment creates a robust network architecture in OCI, featuring
- A Virtual Cloud Network (VCN) with four subnets for distinct traffic types
- Two Palo Alto firewalls in an HA configuration to ensure failover and redundancy
- A Windows Server 2022 instance for testing connectivity through the firewall
- Security lists and route tables to control traffic flow
- IAM policies to enable HA failover by managing secondary IPs

### Architecture Details
- **Networking**
  - VCN CIDR - `10.1.0.0/16`
  - Subnets
    - Management - `10.1.0.0/24` – Hosts the management interfaces of both firewalls
    - Untrust - `10.1.1.0/24` – Handles external traffic to/from the internet
    - Trust - `10.1.2.0/24` – Contains the Windows Server and internal traffic
    - HA - `10.1.3.0/24` – Dedicated for HA communication between firewalls
  - An internet gateway enables inbound and outbound traffic for the management and untrust subnets via the VCN’s default route table. The trust subnet uses a custom route table to direct all traffic through the firewall’s secondary trust IP (`10.1.2.110`)

- **Security Lists**
  - **Management Subnet** - Allows SSH (port 22) and HTTPS (port 443) inbound from your public IP, with all outbound traffic permitted
  - **Untrust Subnet** - Permits all inbound traffic (firewall-controlled) and RDP (port 3389) from your public IP to the secondary IP (`10.1.1.110`), with all outbound traffic allowed
  - **Trust Subnet** - Allows all inbound traffic (firewall-controlled) and all outbound traffic
  - **HA Subnet** - Permits all traffic within the HA subnet (`10.1.3.0/24`) for both ingress and egress, ensuring HA communication

- **Firewalls**
  - **Firewall A** (Active)
    - Management - `10.1.0.10` (public IP assigned)
    - Untrust - `10.1.1.10` (primary), `10.1.1.110` (secondary, with reserved public IP)
    - Trust - `10.1.2.10` (primary), `10.1.2.110` (secondary)
    - HA1 - `10.1.3.10`
    - HA2 - `10.1.3.110`
  - **Firewall B** (Passive)
    - Management - `10.1.0.11` (public IP assigned)
    - Untrust - `10.1.1.11`
    - Trust - `10.1.2.11`
    - HA1 - `10.1.3.11`
    - HA2 - `10.1.3.111`

- **Windows Server** - A Windows Server 2022 VM in the trust subnet at `10.1.2.20`, with no public IP. The firewall is disabled on boot via `user_data` for testing purposes

- **HA Configuration**
  - The HA setup uses HA1 for control traffic (heartbeat) and HA2 for state synchronization
  - A Dynamic Group (`HA-FIREWALL-GROUP`) and IAM policy enable the firewalls to manage secondary IPs during failover, ensuring seamless transition of the untrust secondary IP (`10.1.1.110`) and trust secondary IP (`10.1.2.110`)

## Files
The project is organized into multiple files to promote modularity and clarity
- `ociprovider.tf` - Configures the OCI provider with tenancy and user credentials
- `main.tf` - Specifies Terraform provider requirements and version constraints
- `locals.tf` - Defines naming prefixes for resources to ensure consistent naming across the deployment
- `variables.tf` - Declares input variables such as OCIDs, region, and public IP
- `terraform.tfvars` - Stores variable values (update with your details before deployment)
- `terraform.tfvars.template` - A template for `terraform.tfvars` with placeholder values
- `oci-networking.tf` - Creates the VCN, subnets (management, untrust, trust, HA), internet gateway, and default route table
- `routing-static.tf` - Configures a custom route table for the trust subnet to route traffic through the firewall
- `securitylist.tf` - Defines security rules for each subnet to control traffic flow
- `firewall.tf` - Deploys two Palo Alto firewalls (A and B) with their respective interfaces and secondary IPs
- `windows.tf` - Deploys the Windows Server in the trust subnet
- `oci-iam.tf` - Creates a Dynamic Group and IAM policies to support HA failover by allowing secondary IP management
- `firewall-configs\firewall-a-config.xml` - Configuration file for Firewall A
- `firewall-configs\firewall-b-config.xml` - Configuration file for Firewall B

## Prerequisites
Before starting, ensure you have the following
- An OCI account with a compartment where you have permission to create resources.
- An API key pair generated in OCI, with the following details noted
  - `tenancy_ocid` - Your tenancy OCID
  - `user_ocid` - Your user OCID
  - `fingerprint` - The fingerprint of your API key
  - `private_key_path` - The file path to your private key
  - `region` - Your OCI region (e.g., `us-ashburn-1`)
- Terraform installed on your machine (version compatible with the OCI provider)
- Visual Studio Code (VSCode) or another IDE for editing Terraform files (optional but recommended)
- An SSH key pair for firewall access (public key added to `terraform.tfvars`)
- The Palo Alto firewall image OCID from the OCI Marketplace (e.g., for version 10.1.14-h9)
- Your public IP address for security list rules (used in `my_public_ip`)

## Deployment Steps

Follow these steps to deploy the infrastructure and configure the firewalls for HA.

### Step 1: Update terraform.tfvars with OCI Credentials and Configuration
1. Copy `terraform.tfvars.template` to `terraform.tfvars`.
2. Open the `terraform.tfvars` file in your editor (e.g., VSCode).
3. Update the following fields with your information.
   - `tenancy_ocid`: Replace `"<your-tenancy-ocid>"` with your OCI tenancy OCID (e.g., `ocid1.tenancy...`).
   - `user_ocid`: Replace `"<your-user-ocid>"` with your OCI user OCID (e.g., `ocid1.user...`).
   - `fingerprint`: Replace `"<your-fingerprint>"` with the fingerprint of your API key (e.g., `12:34:56...`).
   - `private_key_path`: Replace `"<path-to-private-key>"` with the local path to your private key file (e.g., `/path/to/private-key.pem`).
   - `compartment_ocid`: Replace `"<your-compartment-id>"` with your OCI compartment OCID (e.g., `ocid1.compartment...`).
   - `region`: Replace `"<your-region>"` with your OCI region (e.g., `us-ashburn-1`).
   - `environment_name`: Replace `"<your-environment-name>"` with your environment name (e.g., `cabbage`).
   - `location`: Replace `"<your-location>"` with your location identifier (e.g., `eastus`).
   - `my_public_ip`: Replace `"<your-public-ip>"` with your public IP for SSH/HTTPS access (e.g., `203.0.113.5/32`).
   - `firewall_image_ocid`: Replace `"<your-firewall-image-ocid>"` with the Palo Alto VM-Series image OCID from OCI Marketplace (e.g., `ocid1.image...`).
   - `ssh_public_key`: Replace `"<your-ssh-public-key>"` with your SSH public key (e.g., content of `palo_alto_key.pub`, such as `ssh-rsa AAAAB3NzaC1yc2E...`).
4. Save the file.

### Step 2: Initialize and Deploy the OCI Project
1. Open a terminal in the project directory.
2. Run `terraform init` to initialize the Terraform working directory and download providers.
3. (Optional) Run `terraform plan` to preview the changes Terraform will make. Review the output to ensure it looks correct.
4. Run `terraform apply` to deploy the OCI resources. Type `yes` when prompted to confirm. This will create the VCN, subnets, firewall, and Windows Server.

### Step 3: Retrieve the Firewall Public IPs
1. After deployment, Terraform will output several values. Note the following.
   - `firewall_mgmt_public_ip_a`: Public IP of Firewall A’s management interface (e.g., `129.213.45.67`) for SSH access.
   - `firewall_mgmt_public_ip_b`: Public IP of Firewall B’s management interface (e.g., `132.145.141.208`) for SSH access.
2. Alternatively, find the public IPs in the OCI Console:
   - Go to **Compute > Instances**.
   - Locate the instances named `fw-cabbage-eastus-001` (Firewall A) and `fw-cabbage-eastus-002` (Firewall B).
   - Note the "Public IP" in the details pane for each management interface.
   You can also view outputs by running the following command.

### Step 4: Manually Associate the Trust Route Table
1. Go to the OCI Console: **Networking > Virtual Cloud Networks**.
2. Select your VCN (`vcn-cabbage-eastus-001`).
3. Under **Resources**, select **Subnets**, then click on the trust subnet (`snet-cabbage-eastus-trust-001`).
4. Click **Edit**, then under **Route Table**, select the trust route table (`rt-cabbage-eastus-trust-001`).
5. Save changes to route trust subnet traffic through the firewall’s trust interface (`10.1.1.10`).

### Step 5: SSH to the Firewall Management Interface and Change Admin Password
1. Open a terminal on your machine.
2. Use the SSH key and management public IP to connect: `ssh -i <private-key-file> admin@<firewall_mgmt_public_ip_a>` (e.g., `ssh -i palo_alto_key admin@129.213.45.67`).
3. You should now be logged into the firewall CLI as the `admin` user.
4. Enter configuration mode: `configure`.
5. Change the admin password for GUI access: `set mgt-config users admin password`.
6. Enter a new password when prompted, then confirm it.
7. Commit the change: `commit`.
8. Exit configuration mode: `exit`.
9. Repeat the process for Firewall B using `firewall_mgmt_public_ip_b`.

### Step 6: Update MY-PUBLIC-IP in the XML Configuration File
1. Open the `firewall-configs\firewall-a-config.xml` and `firewall-configs\firewall-b-config.xml` files in your editor (e.g., VSCode).
2. Find and replace the placeholder IP `5.5.5.5/32` with your actual public IP (the same value used for `my_public_ip` in `terraform.tfvars`, e.g., `203.0.113.5/32`).
   - Search for `<ip-netmask>5.5.5.5/32</ip-netmask>` under the `MY-PUBLIC-IP` address entry.
   - Replace it with `<ip-netmask>YOUR_PUBLIC_IP/32</ip-netmask>` (e.g., `<ip-netmask>203.0.113.5/32</ip-netmask>`).
3. Save the files.

### Step 7: Import the XML Configuration to the Firewall via GUI
1. Access Firewall A’s GUI via HTTPS: `https://<firewall_mgmt_public_ip_a>` in your browser (e.g., `https://129.213.45.67`).
2. Log in with username `admin` and the password you set in Step 5.
3. Go to **Device > Setup > Operations > Import Named Configuration Snapshot**.
4. Click **Choose File**, select your updated XML configuration file (e.g., `firewall-configs\firewall-a-config.xml`), and click **OK**.
5. Navigate to **Device > Setup > Operations > Load Named Configuration Snapshot**, select the uploaded file, and click **Load**.
6. Click **Commit** in the top-right corner to save the changes. Note that after the commit, the admin password will be reset to `2Plus2cabbage!` due to the imported XML configuration.
7. Repeat the process for Firewall B via GUI at `https://<firewall_mgmt_public_ip_b>` using the `firewall-configs\firewall-b-config.xml` file.

### Step 8: Manually Associate the Trust Route Table
1. Configure the trust subnet to use the custom trust route table. 
2. In the OCI Console, go to **Networking > Virtual Cloud Networks > [your VCN] > Subnets > [trust subnet] > Edit**, set the route table to the trust route table (named with the prefix from `locals.tf` and suffix `-trust-001`), and save changes.

### Step 9: Access the Windows Server via RDP
1. Use the untrust secondary public IP (`firewall_untrust_secondary_reserved_public_ip_a`), port 3389, username `opc`, and initial password from the OCI Console (**Compute > Instances > [select instance vm-cabbage-eastus-windows001] > Resources > Instance Access > Show Initial Password**).
2. Open your Remote Desktop client (e.g., Microsoft Remote Desktop).
3. Enter the firewall’s untrust public IP (terraform output `firewall_untrust_secondary_reserved_public_ip_a`, e.g., `150.136.200.108`).

### Step 10: Verify Connectivity from the Windows Server
1. Verify connectivity from the Windows Server: Open Command Prompt or PowerShell, test internet access with `ping google.com`, and confirm connectivity is successful.

### Step 11: Initiate Failover from Firewall A to Firewall B
1. Log in to Firewall A’s GUI at `https://<firewall_mgmt_public_ip_a>` using the updated admin credentials (`admin`/`2Plus2cabbage!`).
2. Navigate to **Device > High Availability > Operational Commands**, click **Suspend local device** to trigger failover to Firewall B.
3. Confirm that the RDP connection to the Windows Server remains uninterrupted.

### Step 12: Clean Up Resources
1. Reset the trust subnet route table to default in the OCI Console to ensure Terraform can destroy the project (Terraform will fail if the manual change from Step 4 is left in place):
   - Go to **Networking > Virtual Cloud Networks**.
   - Select your VCN (`vcn-<environment_name>-<location>-001`, e.g., `vcn-cabbage-eastus-001`).
   - Under **Resources**, select **Subnets**, then click on the trust subnet (`snet-<environment_name>-<location>-trust-001`, e.g., `snet-cabbage-eastus-trust-001`).
   - Click **Edit**, then under **Route Table**, select the default route table for the VCN (named `Default Route Table for vcn-<environment_name>-<location>-001`, e.g., `Default Route Table for vcn-cabbage-eastus-001`).
   - Save changes to remove the association with the trust route table.
2. In the terminal, run `terraform destroy` to remove all resources. Type `yes` to confirm.
3. Verify in the OCI Console that all resources (VCN, subnets, instances) are deleted.

## Potential costs and licensing
- The resources deployed using this Terraform configuration should generally incur minimal to no costs, provided they are terminated promptly after creation; the firewall instance (VM.Standard3.Flex, 3 OCPUs, 42 GB memory) and Windows Server (VM.Standard.E2.1) may incur compute and storage charges.
- It is important to understand your cloud provider's billing structure, trial periods, and any potential costs associated with the deployment of resources in public cloud environments; check OCI pricing for compute instances and Marketplace images.
- You are also responsible for any applicable software licensing or other charges that may arise from the deployment and usage of these resources, including Palo Alto licensing for the VM-Series firewall and Windows Server licensing.
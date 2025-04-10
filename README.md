# Terraform AWS Infrastructure for Nginx Docker Container

This repository contains Terraform configuration files to automatically provision a basic AWS infrastructure environment. The environment includes a custom VPC, a public subnet, security groups, and an EC2 instance. Upon creation, the EC2 instance is provisioned using `remote-exec` to install Docker and run a standard Nginx web server container, accessible on port 8080.

**Objective:** Demonstrate infrastructure provisioning on AWS using Terraform, covering networking, compute, security, and instance bootstrapping with Docker.

---

## Proof of Execution (Screenshots)

**1. Nginx Running on EC2 Server**  
*Description: This screenshot shows the default Nginx welcome page accessed via a web browser using the EC2 instance's public IP address on port 8080 (e.g., `http://<EC2_PUBLIC_IP>:8080`).*

![Nginx Running on EC2](screenshots/nginx_running_screenshot.png)

---

## Prerequisites

Ensure you have the following before applying this Terraform configuration:

1. **Terraform CLI** (version 1.x or later) installed on your machine.
2. **AWS Account** with active access.
3. **AWS Credentials** configured via:
   - Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), or
   - Shared credentials file (`~/.aws/credentials`), or
   - IAM instance profile (if running from EC2).
4. **SSH Key Pair:** Path to both your public key (`.pub`) and private key (`.pem` or similar).
5. **Input Variables File:** Create a `terraform.tfvars` file with values for the defined variables.

---

## Infrastructure Components

This configuration provisions the following AWS resources:

1. **VPC (`aws_vpc`):** Custom VPC with a specified CIDR block.
2. **Subnet Module (`./modules/subnet`):**
   - **Subnet (`aws_subnet`):** Public subnet in a specific Availability Zone.
   - **Internet Gateway (`aws_internet_gateway`):** Enables internet access.
   - **Route Table (`aws_default_route_table`):** Adds default route to the IGW (`0.0.0.0/0`).
3. **Security Group (`aws_security_group`):**
   - Allows inbound SSH (port 22) and Nginx (port 8080) from `var.my_ip`.
   - Allows outbound traffic to `0.0.0.0/0` (assumed standard internet access).
4. **AMI Data Source (`aws_ami`):** Finds latest Amazon Linux 2 AMI ID.
5. **Key Pair (`aws_key_pair`):** Imports SSH public key.
6. **EC2 Instance (`aws_instance`):**
   - Uses the found AMI ID and specified instance type.
   - Launches into the public subnet with a public IP.
   - Uses the defined security group and key pair.
7. **Provisioners:**
   - **`file`:** Uploads `entry-script.sh` to the instance.
   - **`remote-exec`:** SSHs into the instance and executes the script.
8. **Entry Script (`entry-script.sh`):**
   - Installs and starts Docker.
   - Adjusts Docker socket permissions.
   - Adds `ec2-user` to the Docker group.
   - Pulls and runs the Nginx container (host port 8080 mapped to container port 80).

---

## File Structure

- `main.tf`: Core AWS resources (VPC, EC2, SG, Key Pair, AMI, module call).
- `variables.tf`: Declares input variables.
- `outputs.tf`: Defines outputs (AMI ID, EC2 Public IP).
- `entry-script.sh`: Bootstrap script for EC2 instance.
- `modules/subnet/main.tf`: Subnet, IGW, and route table setup.
- `terraform.tfvars` (user-created): Provides variable values.

---

## How to Run

1. **Clone the Repository:**
   ```bash
   git clone <your-repo-url>
   cd <your-repo-directory>
   ```

2. **Create `terraform.tfvars`:** Example:
   ```hcl
   vpc_cidr_block       = "10.0.0.0/16"
   subnet_cidr_block    = "10.0.10.0/24"
   avail_zone           = "ap-south-1a"
   env_prefix           = "dev"
   my_ip                = "YOUR_PUBLIC_IP/32" # e.g., "85.246.32.98/32"
   instance_type        = "t2.micro"
   public_key_location  = "~/.ssh/id_rsa.pub"
   private_key_location = "~/.ssh/id_rsa"
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan the Infrastructure:**
   ```bash
   terraform plan
   ```

5. **Apply Configuration:**
   ```bash
   terraform apply
   ```
   - Type `yes` when prompted.
   - Note the `ec2_public_ip` from the output.

6. **Access the Web Server:**
   - Visit `http://<EC2_PUBLIC_IP>:8080` in your browser.

7. **Destroy Resources (Cleanup):**
   ```bash
   terraform destroy
   ```
   - Type `yes` when prompted.

---

## Input Variables (`variables.tf`)

| Name                   | Description                                             | Type   | Required |
|------------------------|---------------------------------------------------------|--------|----------|
| `vpc_cidr_block`       | CIDR block for the VPC.                                 | string | Yes      |
| `subnet_cidr_block`    | CIDR block for the public subnet.                       | string | Yes      |
| `avail_zone`           | Availability Zone for the subnet and EC2.              | string | Yes      |
| `env_prefix`           | Prefix for naming resources.                           | string | Yes      |
| `my_ip`                | Public IP address (in CIDR format) for SG rules.       | string | Yes      |
| `instance_type`        | EC2 instance type (e.g., "t2.micro").                 | string | Yes      |
| `public_key_location`  | Path to SSH public key file.                           | string | Yes      |
| `private_key_location` | Path to SSH private key file.                          | string | Yes      |

---

## Outputs (`outputs.tf`)

| Name             | Description                            |
|------------------|----------------------------------------|
| `aws_ami_id`     | ID of the Amazon Linux 2 AMI used.     |
| `ec2_public_ip`  | Public IP address of the EC2 instance. |

---



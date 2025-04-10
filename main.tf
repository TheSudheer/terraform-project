provider "aws" {}

# Variables have been moved to variables.tf

# Create a custom VPC with a name derived from the environment prefix.
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

# The following resources (aws_subnet, aws_internet_gateway, aws_default_route_table)
# are now defined in modules/subnet/main.tf.

# Reference the subnet module to assign variable values.
# Variable values are now centralized in a single terraform.tfvars file located
# in the root of the project and can be used anywhere.
module "myapp-subnet" {
  source                 = "./modules/subnet"
  subnet_cidr_block      = var.subnet_cidr_block
  avail_zone             = var.avail_zone
  env_prefix             = var.env_prefix
  vpc_id                 = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}

# Define the security group for the application.
resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  # Ingress rule for SSH access on port 22.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.my_ip]  # Allows only your specific IP (e.g., "85.246.32.98/32")
  }

  # Ingress rule for accessing the Nginx web server on port 8080.
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = [var.my_ip]  # Allows access from the specified IP.
  }

  # Egress rule to permit all outbound traffic.
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"  # "-1" represents all protocols.
    cidr_blocks     = [var.my_ip]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-myapp-sg"
  }
}

# Data source to retrieve the latest Amazon Linux 2 AMI.
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Outputs have been moved to outputs.tf

# Create an AWS key pair for SSH access.
resource "aws_key_pair" "ssh-key" {
  key_name   = "aws-ssh-1"
  public_key = file(var.public_key_location)
}

# Define an EC2 instance for the application server.
resource "aws_instance" "myapp-server" {
  ami                    = data.aws_ami.latest-amazon-linux-image.id
  instance_type          = var.instance_type  # Choose an appropriate instance type.
  subnet_id              = module.myapp-subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  key_name               = aws_key_pair.ssh-key.key_name

  associate_public_ip_address = true
  availability_zone           = var.avail_zone

  # Uncomment the next line to use the user-data script.
  # user_data = file("entry-script.sh")

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_location)
  }

  # Provisioner to upload the entry script to the EC2 instance.
  provisioner "file" {
    source      = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-on-ec2.sh"
  }

  # Remote execution provisioner to run the entry script.
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/entry-script-on-ec2.sh",
      "/home/ec2-user/entry-script-on-ec2.sh"
    ]
  }

  user_data_replace_on_change = true

  tags = {
    Name = "${var.env_prefix}-myapp-server"
  }
}

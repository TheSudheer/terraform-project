#!/bin/bash
set -e

# Update the system and install Docker
sudo yum -y update && sudo yum -y install docker

# Start and enable the Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add the ec2-user to the docker group for non-sudo usage (effective after a relogin)
sudo usermod -aG docker ec2-user

# Run the nginx container in detached mode with proper port mapping.
# Mapping host port 8080 to container port 80.
docker run -d -p 8080:80 nginx

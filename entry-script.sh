#!/bin/bash
set -e

# Update the system and install Docker
yum -y update && yum -y install docker

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Set permissions on Docker socket
chmod 666 /var/run/docker.sock

# Add the current user (default to ec2-user) to the docker group
usermod -aG docker "${USER:-ec2-user}"

# Wait a few seconds to ensure Docker is fully ready
sleep 5

# Pull and run the NGINX container in detached mode
docker run -d --name nginx-container -p 8080:80 nginx

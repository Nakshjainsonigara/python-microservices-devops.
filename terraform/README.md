# Terraform Deployment (AWS)

This directory provisions an EC2 instance, installs Docker + Docker Compose via user data, and runs the microservices stack using DockerHub images.

## Prerequisites
- Terraform 1.5+
- AWS credentials with permission for EC2, VPC read, and security groups
- Public DockerHub images: `<dockerhub_username>/{backend,frontend,logger}:<tag>`

## Variables
- region: AWS region (default `us-east-1`)
- instance_type: EC2 type (default `t3.micro`)
- key_name: Optional EC2 key pair for SSH
- ssh_ingress_cidr: CIDR allowed for SSH (default `0.0.0.0/0`)
- dockerhub_username: Your DockerHub username (required)
- image_tag: Image tag to deploy (default `latest`)
- allowed_client_cidr: CIDR allowed to access services (default `0.0.0.0/0`)

## Example terraform.tfvars
region = "us-east-1"
instance_type = "t3.micro"
key_name = "my-ec2-keypair"
ssh_ingress_cidr = "203.0.113.4/32"  # restrict SSH to your IP
allowed_client_cidr = "0.0.0.0/0"
dockerhub_username = "your-dockerhub-username"
image_tag = "latest"

## Deploy
- cd terraform
- terraform init
- terraform plan -out=tfplan
- terraform apply tfplan

Outputs include the instance `public_ip` and a `frontend_url` you can open in a browser.

## SSH Access
- Default user: `ec2-user` (Amazon Linux 2)
- Command: ssh -i /path/to/key.pem ec2-user@<public_ip>

After connecting:
- cd /opt/app
- docker-compose ps
- docker-compose logs -f frontend
- docker-compose pull && docker-compose up -d  # redeploy with new tags

## Tear Down
- terraform destroy

## Notes
- For production, restrict `ssh_ingress_cidr` and `allowed_client_cidr` to your networks.
- Ensure CI has pushed images for the chosen `image_tag` before applying.

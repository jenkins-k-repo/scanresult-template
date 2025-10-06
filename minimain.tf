# main.tf

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "my-safe-bucket-123456789"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Environment = "test"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-allow-https"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = "vpc-123456"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # <== Mild issue: open to the world
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

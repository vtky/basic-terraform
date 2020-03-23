# AWS Regions
#us-east-2       # US East (Ohio)
#us-east-1       # US East (N. Virginia)
#us-west-1       # US West (N. California)
#us-west-2       # US West (Oregon)
#ap-east-1       # Asia Pacific (Hong Kong)
#ap-south-1      # Asia Pacific (Mumbai)
#ap-northeast-3  # Asia Pacific (Osaka-Local)
#ap-northeast-2  # Asia Pacific (Seoul)
#ap-southeast-1  # Asia Pacific (Singapore)
#ap-southeast-2  # Asia Pacific (Sydney)
#ap-northeast-1  # Asia Pacific (Tokyo)
#ca-central-1    # Canada (Central)
#cn-north-1      # China (Beijing)
#cn-northwest-1  # China (Ningxia)
#eu-central-1    # Europe (Frankfurt)
#eu-west-1       # Europe (Ireland)
#eu-west-2       # Europe (London)
#eu-west-3       # Europe (Paris)
#eu-north-1      # Europe (Stockholm)
#me-south-1      # Middle East (Bahrain)
#sa-east-1       # South America (Sao Paulo)
provider "aws" {
  profile    = "default"
  region     = "ap-southeast-1"
}

# AWS Account ID: 136693071363
# debian-10-amd64-20200210-166 
data "aws_ami" "debian10" {
  most_recent   = true
  owners        = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-10-amd64-20200210-166"]
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"

  ingress {
    description       = "Allow all inbound traffic"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  egress {
    description       = "Allow all outbound traffic"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  tags = {
    Name = "allow_all"
  }
}


# ssh-keygen -t rsa -b 4096 -f tf-rsa-key -C ""
resource "aws_key_pair" "tfkey" {
  key_name   = "tfkey"
  public_key = file("tf-rsa-key.pub")
}

resource "aws_instance" "basic" {
  ami                     = data.aws_ami.debian10.id
  instance_type           = "t2.micro"
  key_name                = aws_key_pair.tfkey.key_name
  vpc_security_group_ids  = [aws_security_group.allow_all.id]

  tags = {
    Name = "basic"
  }

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file("tf-rsa-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt upgrade -y"
    ]
  }
}
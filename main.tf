provider "aws" {
  profile    = var.profile
  region     = var.aws_region
  shared_credentials_file = var.shared_credentials_file
}

# Setup a specific VPC
resource "aws_vpc" "ex-vpc" {
    cidr_block = var.aws_vpc_cidr_block

    # gives you an internal domain name
    enable_dns_support = "true"

    # gives you an internal host name
    enable_dns_hostnames = "true"
    enable_classiclink = "false"

    # instance_tenancy: if it is true, your ec2 will be the only instance in an AWS physical hardware. Sounds good but expensive.
    instance_tenancy = "default"
}

resource "aws_subnet" "ex-subnet-public-1" {
    vpc_id = aws_vpc.ex-vpc.id
    cidr_block = var.aws_vpc_subnet_cidr_block
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = var.aws_az
}

resource "aws_internet_gateway" "ex-igw" {
    vpc_id = aws_vpc.ex-vpc.id
}

resource "aws_route_table" "ex-public-crt" {
    vpc_id = aws_vpc.ex-vpc.id

    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0"
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.ex-igw.id
    }
}

resource "aws_route_table_association" "prod-crta-public-subnet-1"{
    subnet_id = aws_subnet.ex-subnet-public-1.id
    route_table_id = aws_route_table.ex-public-crt.id
}


# AWS Account ID: 136693071363
# debian-10-amd64-20200803-347
# aws ec2 describe-images --region ap-southeast-1 --owners 136693071363 --query 'sort_by(Images, &CreationDate)[].[CreationDate,Name,ImageId]' --output table --profile vtky
data "aws_ami" "debian10" {
  most_recent   = true
  owners        = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-10-amd64-20200803-347"]
  }
}

resource "aws_security_group" "allow_all" {
  vpc_id = aws_vpc.ex-vpc.id

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
  count                   = var.instance_count
  ami                     = data.aws_ami.debian10.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.tfkey.key_name
  vpc_security_group_ids  = [aws_security_group.allow_all.id]

  subnet_id = aws_subnet.ex-subnet-public-1.id

  tags = {
    Name = "basic-${count.index + 1}"
  }

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file("tf-rsa-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt -y install gnupg wget curl vim"
    ]
  }
}



# resource "aws_spot_instance_request" "spot" {
#   count                   = var.instance_count
#   ami                     = data.aws_ami.debian10.id
#   instance_type           = "t2.micro"
#   spot_price              = "0.03"
#   key_name                = aws_key_pair.tfkey.key_name
#   vpc_security_group_ids  = [aws_security_group.allow_all.id]

#   tags = {
#     Name = "spot-${count.index + 1}"
#   }

#   connection {
#     type        = "ssh"
#     user        = "admin"
#     private_key = file("tf-rsa-key")
#     host        = self.public_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt update",
#       "sudo apt upgrade -y",
#       "sudo apt -y install gnupg nmap wget curl tcpdump",
#       "curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall",
#       "chmod 755 msfinstall",
#       "./msfinstall",
#       "msfdb init --use-defaults"
#     ]
#   }
# }
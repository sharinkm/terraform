provider "aws" {}

variable vpc_cidr_block{}
variable subnet_cidr_block{}
variable avail_zone{}
variable internet_cidr_block{}
variable my_ip{}
variable my_instance_type{}
variable my_pub_key_location{}

resource "aws_vpc" "my-vpc"{

    cidr_block = var.vpc_cidr_block

    tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "dev-subnet"{

    vpc_id = aws_vpc.my-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone

    tags = {
    Name = "dev-subnet"
  }

}

resource "aws_internet_gateway" "dev-igw"{
    vpc_id = aws_vpc.my-vpc.id

    tags = {
    Name = "dev-igw"
  }

}
resource "aws_default_route_table" "dev-default-rt"{
    default_route_table_id = aws_vpc.my-vpc.default_route_table_id

    route {
    cidr_block = var.internet_cidr_block
    gateway_id = aws_internet_gateway.dev-igw.id
  }

  tags = {
    Name = "dev-default-rt"
  }

}

resource "aws_default_security_group" "defaul-dev-sg"{

    vpc_id = aws_vpc.my-vpc.id

    ingress {
    protocol  = "TCP"
    from_port = 22
    to_port   = 22
    cidr_blocks = [var.my_ip]
  }
   ingress {
    protocol  = "TCP"
    from_port = 8080
    to_port   = 8080
    cidr_blocks = [var.internet_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr_block]
  }

  tags = {
    Name = "default-dev-sg"
  }
}


data "aws_ami" "my-latest-ubntu-ama-image"{
    most_recent = true
    filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20231207"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "instance_id"{
    value = data.aws_ami.my-latest-ubntu-ama-image.id
}

resource "aws_key_pair" "ssh-key"{
    key_name = "server-ssh-key"
    public_key = file(var.my_pub_key_location)
}

resource "aws_instance" "dev-server"{
    ami = data.aws_ami.my-latest-ubntu-ama-image.id
    instance_type = var.my_instance_type
    subnet_id = aws_subnet.dev-subnet.id
    vpc_security_group_ids = [aws_default_security_group.defaul-dev-sg.id]
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name
    availability_zone = var.avail_zone

    tags = {
    Name = "dev-web-server"
  }

  user_data = "${file("init.sh")}"
  user_data_replace_on_change = true

}


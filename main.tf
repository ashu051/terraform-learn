provider "aws" {}

variable vpc_cidr_block {}
variable subnet_cidr_block {}

variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {
  
}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name : "${var.env_prefix}-subnet-1"
    }
}


resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name : "${var.env_prefix}-igw"
    }
}

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }

    tags = {
        Name : "${var.env_prefix}-main-rtb"
    }
}

# resource "aws_route_table_association" "a-rtb-subnet" {
#     subnet_id = aws_subnet.myapp-subnet1.id
#     route_table_id = aws_route_table.myapp-route-table.id
# }
resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH access"
    }

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP access"
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.env_prefix}-sg"
    }
}
# data "aws_ami" "latest-amazon-linux-image"{
#     most_recent = true
#     owners = ["amazon"]
#     filter {
#       name = "name"
#       values = ["ami-0c101f26f147fa7fd"]
#     }
#     filter {
#       name = "virtualization-type"
#       values = ["hvm"]
#     }
# }
output "aws_ami_id"{
     value = aws_instance.myapp-server.ami
}
resource "aws_instance" "myapp-server" {
    ami = "ami-0c101f26f147fa7fd"
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet1.id
    vpc_security_group_ids =[aws_security_group.myapp-sg.id]
    availability_zone =  var.avail_zone
    associate_public_ip_address = true
    key_name = "server-key-pair"
    user_data = file("entry-script.sh")
    tags = {
        Name:"${var.env_prefix}-server"
    }

}
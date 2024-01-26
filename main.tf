# Create a vpc 
resource "aws_vpc" "terra_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "my_vpc"
  }
}
# Create an internet gateway
resource "aws_internet_gateway" "terra_IGW" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    name = "my_IGW"
  }
}
# Create a custom route table
resource "aws_route_table" "terra_route_table" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    name = "my_route_table"
  }
}
# create route
resource "aws_route" "terra_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id  = aws_internet_gateway.terra_IGW.id
  route_table_id = aws_route_table.terra_route_table.id
}
# create a subnet
resource "aws_subnet" "terra_subnet" {
  vpc_id = aws_vpc.terra_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone
  
  tags = {
    name = "my_subnet"
  }
}
# associate internet gateway to the route table by using subnet
resource "aws_route_table_association" "terra_assoc" {
  subnet_id = aws_subnet.terra_subnet.id
  route_table_id = aws_route_table.terra_route_table.id
}
# create security group to allow ingoing ports
resource "aws_security_group" "terra_SG" {
  name        = "sec_group"
  description = "security group for the EC2 instance"
  vpc_id      = aws_vpc.terra_vpc.id
  ingress = [
    {
      description      = "https traffic"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0", aws_vpc.terra_vpc.cidr_block]
      ipv6_cidr_blocks  = []
      prefix_list_ids   = []
      security_groups   = []
      self              = false
    },
    {
      description      = "http traffic"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0", aws_vpc.terra_vpc.cidr_block]
      ipv6_cidr_blocks  = []
      prefix_list_ids   = []
      security_groups   = []
      self              = false
    },
    {
      description      = "ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0", aws_vpc.terra_vpc.cidr_block]
      ipv6_cidr_blocks  = []
      prefix_list_ids   = []
      security_groups   = []
      self              = false
    }
  ]
  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "Outbound traffic rule"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  tags = {
    name = "allow_web"
  }
}

# create a network interface with private ip from step 4
resource "aws_network_interface" "terra_net_interface" {
  subnet_id = aws_subnet.terra_subnet.id
  security_groups = [aws_security_group.terra_SG.id]
}
# assign a elastic ip to the network interface created in step 7
resource "aws_eip" "terra_eip" {
  vpc = true
  network_interface = aws_network_interface.terra_net_interface.id
  associate_with_private_ip = aws_network_interface.terra_net_interface.private_ip
  depends_on = [aws_internet_gateway.terra_IGW, aws_instance.terra_ec2]
}
# create an ubuntu server and install/enable apache2
resource "aws_instance" "terra_ec2" {
  ami = var.ami
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  key_name = "mykey"
  
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.terra_net_interface.id
  }
  
  user_data = file("${path.module}/user_data.sh")
  
  tags = {
    Name = "web_server"
  }
}
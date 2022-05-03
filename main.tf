#declare the provider of the 
provider "aws" {
    region = "us-east-1" 
}
# create vpc 
resource "aws_vpc" "cedou_vpc" {
cidr_block = "10.0.0.0/16"
tags = {
    Name = "cedounga"
    team = "dev"
    owner= "cedou"
}
}
#create the internet gateway 
resource "aws_internet_gateway" "cedou-igw" {
vpc_id =  aws_vpc.cedou_vpc.id 
tags = {
    Name = "Cedou-igw"
}
}
#create route table 
resource "aws_route_table" "cedou-rt" {
vpc_id =  aws_vpc.cedou_vpc.id 
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.cedou-igw.id
} 
tags = {
    Name = "cedou-RT"
}
}
#create subnet
resource "aws_subnet" "public-subnet" {
vpc_id =  aws_vpc.cedou_vpc.id 
cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1a" 
tags ={
    Name = "public-subnet"
} 
}
#associate subnet with route table 
resource "aws_route_table_association" "association" {
    subnet_id = aws_subnet.public-subnet.id
    route_table_id = aws_route_table.cedou-rt.id
  
}
#create security group to allow port 22 ,80 ,443
resource "aws_security_group" "cedou_sg" {
vpc_id = aws_vpc.cedou_vpc.id
name = "cedou.sg"
description = "allow ssh access to developpers"
ingress {
    description = "SSH"
    from_port = 22 
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
} 
ingress {
    description = "HTTP"
    from_port = 80 
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
} 
ingress {
    description = "HTTPS"
    from_port = 443 
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
egress {
    from_port = 0 
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
} 
tags = {
  Name = "cedou.sg"
  owner = "cedounga"
}
}
#Create a network interface with an IP in the subnet that was created in Step4 
resource "aws_network_interface" "cedou-NT" {
subnet_id = aws_subnet.public-subnet.id
private_ips =  ["10.0.1.50"]
security_groups = [aws_security_group.cedou_sg.id]
}

#Assign an elastic IP to the network interface created in step 7 
resource "aws_eip" "cedou-elastic-ip" {
    vpc = true
    network_interface = aws_network_interface.cedou-NT.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.cedou-igw]
  
}

#create an ubuntu server and install /enable apache2 
resource "aws_instance" "cedou-ubuntu" {
    instance_type = "t2.nano"
    ami = "ami-09d56f8956ab235b3"
    availability_zone = "us-east-1a"
    key_name = "aprildevkey"
    network_interface {
      device_index = 0
      network_interface_id =   aws_network_interface.cedou-NT.id
    }
  user_data = <<-EOF
  #!/bin/bash
  sudo apt get update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  sudo systemctl enable apache2 
  echo "<h1>WE DID IT!</h1>" | sudo tee /var/www/html/index.html
  EOF

}
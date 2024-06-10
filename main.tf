#configure VPC
resource "aws_vpc" "VigneshVPC" {
  cidr_block       = var.cidr
  instance_tenancy = "default"

  tags = {
    Name = "Vignesh_VPC"
  }
}

#Congure Public Subnet

resource "aws_subnet" "VigneshSubnetPublic" {
  vpc_id     = aws_vpc.VigneshVPC.id
  cidr_block = var.publiccidrblock
  availability_zone ="ap-south-1a"
  tags = {
    Name = "VigneshSubnet_Public"
  }
}

#configure Private Subnet
resource "aws_subnet" "VigneshSubnetPrivate" {
  vpc_id     = aws_vpc.VigneshVPC.id
  cidr_block = var.privatecidrblock
  availability_zone ="ap-south-1b"
  tags = {
    Name = "VigneshSubnet_Private"
  }
}

#Creating IGW
resource "aws_internet_gateway" "VigneshIgw" {
  vpc_id = aws_vpc.VigneshVPC.id

  tags = {
    Name = "Vignesh_Igw"
  }
}


#Public RouteTable Creation
resource "aws_route_table" "VigneshPublicRT" {
  vpc_id = aws_vpc.VigneshVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VigneshIgw.id
  }

  tags = {
    Name = "VigneshPublic_RT"
  }
}

#Publicroute table assosication
resource "aws_route_table_association" "PublicrouteVignesh" {
  subnet_id      = aws_subnet.VigneshSubnetPublic.id
  route_table_id = aws_route_table.VigneshPublicRT.id
}

#Public Securygroup creation
resource "aws_security_group" "BastionServerAccess" {
  name        = "Public"
  description = "Allow access to bastionServer"
  vpc_id      = aws_vpc.VigneshVPC.id

  tags = {
    Name = "BastionServer_Access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sshfromoutside" {
  security_group_id = aws_security_group.BastionServerAccess.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.BastionServerAccess.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Private secuiry group creation


resource "aws_security_group" "DBSErver" {
  name        = "allow_tls from bastion"
  description = "Allow access to bastionServer"
  vpc_id      = aws_vpc.VigneshVPC.id

  tags = {
    Name = "DB_SErver"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sshfrombastion" {
  security_group_id = aws_security_group.DBSErver.id
  cidr_ipv4         = "172.16.1.0/24"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_allFromBastion" {
  security_group_id = aws_security_group.DBSErver.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#Elastic IP Creation
resource "aws_eip" "Nat-Gateway-EIP" {
  domain = "vpc"
}

#Nat GateWAy Creation


resource "aws_nat_gateway" "VigneshNATGateway" {
  allocation_id = aws_eip.Nat-Gateway-EIP.id
  subnet_id     = aws_subnet.VigneshSubnetPrivate.id
  tags = {
    Name = "Vignesh_NATGateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
depends_on = [aws_internet_gateway.VigneshIgw]
}


#Private RouteTable Creation
resource "aws_route_table" "VigneshPrivateRT" {
  vpc_id = aws_vpc.VigneshVPC.id

  route {
    cidr_block = "172.16.2.0/24"
    gateway_id = aws_nat_gateway.VigneshNATGateway.id
  }

  tags = {
    Name = "VigneshPrivate_RT"
  }
}

#Privateroute table assosication
resource "aws_route_table_association" "privaterouteVignesh" {
  subnet_id      = aws_subnet.VigneshSubnetPrivate.id
  route_table_id = aws_route_table.VigneshPrivateRT.id
}

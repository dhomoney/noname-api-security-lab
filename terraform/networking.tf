#Creation of noname VPC
resource "aws_vpc" "noname_vpc" {
  cidr_block       = var.noname_cidr
  instance_tenancy = "default"
  tags = {
    Name = "nnw-${var.customer_name}-nvpc"
  }
}

#Creation of app VPC
resource "aws_vpc" "app_vpc" {
  cidr_block       = var.app_cidr
  instance_tenancy = "default"
  tags = {
    Name = "nnw-${var.customer_name}-avpc"
  }
}

# Creation of noname Subnet
resource "aws_subnet" "noname_subnet" {
  vpc_id                  = aws_vpc.noname_vpc.id
  cidr_block              = var.noname_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "nnw-${var.customer_name}-ns"
  }
}

# Creation of app Subnet1
resource "aws_subnet" "app_subnet1" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.app_subnet1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "nnw-${var.customer_name}-as"
  }
}

# Creation of app Subnet2
resource "aws_subnet" "app_subnet2" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.app_subnet2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "nnw-${var.customer_name}-as2"
  }
}

#Creation of noname Internet Gateway
resource "aws_internet_gateway" "noname_gw" {
  vpc_id = aws_vpc.noname_vpc.id
  tags = {
    Name = "nnw-${var.customer_name}-ngw"
  }
}

#Creation of app Internet Gateway
resource "aws_internet_gateway" "app_gw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "nnw-${var.customer_name}-agw"
  }
}

# Create VPC peering
resource "aws_vpc_peering_connection" "app_to_noname" {
  vpc_id      = aws_vpc.app_vpc.id
  peer_vpc_id = aws_vpc.noname_vpc.id
  auto_accept = true
  tags = {
    Name = "nnw-${var.customer_name}-vp"
  }
}

# Creation of noname Route Table
resource "aws_route_table" "noname_routetable" {
  vpc_id = aws_vpc.noname_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.noname_gw.id
  }
  route {
    cidr_block                = var.app_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.app_to_noname.id
  }
  tags = {
    Name = "nnw-${var.customer_name}-nrt"
  }
}

# Creation of app Route Table
resource "aws_route_table" "app_routetable" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_gw.id
  }
  route {
    cidr_block                = var.noname_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.app_to_noname.id
  }
  tags = {
    Name = "nnw-${var.customer_name}-art"
  }
}

# Associate noname route table with subnet
resource "aws_route_table_association" "noname" {
  subnet_id      = aws_subnet.noname_subnet.id
  route_table_id = aws_route_table.noname_routetable.id
}

# Associate app route table with subnet1
resource "aws_route_table_association" "app_server1" {
  subnet_id      = aws_subnet.app_subnet1.id
  route_table_id = aws_route_table.app_routetable.id
}

# Associate app route table with subnet2
resource "aws_route_table_association" "app_server2" {
  subnet_id      = aws_subnet.app_subnet2.id
  route_table_id = aws_route_table.app_routetable.id
}

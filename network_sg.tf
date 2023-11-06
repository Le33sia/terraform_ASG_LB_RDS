resource "aws_vpc" "demovpc" {
  cidr_block       = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"
tags = {
    Name = "Demo VPC"
  }
}
resource "aws_internet_gateway" "demogateway" {
  vpc_id = aws_vpc.demovpc.id
}
# 1st public subnet 
resource "aws_subnet" "Public_subnet1" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block             = var.Public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"
tags = {
    Name = "Public subnet 1"
  }
}
# 2nd public subnet 
resource "aws_subnet" "Public_subnet2" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block             = var.Public_subnet2_cidr
  map_public_ip_on_launch = true
  availability_zone = "us-west-2b"
tags = {
    Name = "Public subnet 2"
  }
}
# Route Table
resource "aws_route_table" "route" {
    vpc_id = aws_vpc.demovpc.id
route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.demogateway.id
    }
tags = {
        Name = "Route to internet"
    }
}
resource "aws_route_table_association" "rt1" {
    subnet_id = aws_subnet.Public_subnet1.id
    route_table_id = aws_route_table.route.id
}
resource "aws_route_table_association" "rt2" {
    subnet_id = aws_subnet.Public_subnet2.id
    route_table_id = aws_route_table.route.id
}




# 1st private subnet
resource "aws_subnet" "Private_subnet1" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block             = var.Private_subnet1_cidr
  availability_zone = "us-west-2a" 
  map_public_ip_on_launch = false 
  tags = {
    Name = "Private Subnet 1"
  }
}

# 2nd private subnet
resource "aws_subnet" "Private_subnet2" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block             = var.Private_subnet2_cidr
  availability_zone = "us-west-2b" 
  map_public_ip_on_launch = false 
  tags = {
    Name = "Private Subnet 2"
  }
}
# route table for private subnets
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.demovpc.id
  tags = {
    Name = "Private Route Table"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "Private_subnet1" {
  subnet_id      = aws_subnet.Private_subnet1.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route_table_association" "Private_subnet2" {
  subnet_id      = aws_subnet.Private_subnet2.id
  route_table_id = aws_route_table.private_route.id
}

# Security group that should be attached to launch template
resource "aws_security_group" "SGtemplate" {
  name        = "SGtemplate"
  description = "Allow incoming HTTP SSH traffic"
  vpc_id      = aws_vpc.demovpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #cidr_blocks = ["0.0.0.0/0"] 
    security_groups = [aws_security_group.ALBSecurityGroup.id] 
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]  
  }
}


# LB security group
resource "aws_security_group" "ALBSecurityGroup" {
  name        = "LB-security-group"
  description = "Security group for the Application Load Balancer"

  vpc_id = aws_vpc.demovpc.id  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

#security group for database
resource "aws_security_group" "rds-SG" {
  vpc_id = aws_vpc.demovpc.id
  name = "rds-SG"
  description = "Allow inbound mysql traffic"
}
resource "aws_security_group_rule" "allow-mysql" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_group_id = aws_security_group.rds-SG.id
    source_security_group_id = aws_security_group.SGtemplate.id
}
resource "aws_security_group_rule" "allow-outgoing" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_group_id = aws_security_group.rds-SG.id
    cidr_blocks = ["0.0.0.0/0"]
}

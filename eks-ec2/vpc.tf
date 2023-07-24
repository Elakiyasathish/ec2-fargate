# VPC
resource "aws_vpc" "eks-vpc" {
  cidr_block = var.eks_vpc_cidr
  
#VPC must have DNS hostname and DNS resolution or else worker node cannot registered with the cluster
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "${var.project}-${var.environment}-vpc",
    "kubernetes.io/cluster/${var.project}-${var.environment}-cluster" = "shared"
    environment = var.environment
    project = var.project

  }
}

# Public Subnets
resource "aws_subnet" "eks-public" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.eks-vpc.id
  cidr_block        = cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch= true

  tags = {
    Name = "${var.project}-${var.environment}-public-subnet"
    "kubernetes.io/cluster/${var.project}-${var.environment}-cluster" = "shared"
    "kubernetes.io/role/elb" = 1
    environment = var.environment
    project = var.project
  }

}

# Private Subnets
resource "aws_subnet" "eks-private" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.eks-vpc.id
  cidr_block        = cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, count.index + var.availability_zones_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch= true

  tags = {
    Name = "${var.project}-${var.environment}-private-subnet"
    "kubernetes.io/cluster/${var.project}-${var.environment}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"              = 1
    environment = var.environment
    project = var.project

  }
}

# Internet Gateway
resource "aws_internet_gateway" "eks-igw" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "Name" = "${var.project}-${var.environment}-igw"
  }

  depends_on = [aws_vpc.eks-vpc]
}

# Route Table(s)
# Route the public subnet traffic through the IGW
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-igw.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-Default-rt"
    environment = var.environment
    project = var.project
  }
}

# Route table and subnet associations
resource "aws_route_table_association" "internet_access" {
  count = var.availability_zones_count

  subnet_id      = aws_subnet.eks-public[count.index].id
  route_table_id = aws_route_table.main.id
}

# NAT Elastic IP
resource "aws_eip" "main" {
  vpc = true

  tags = {
    Name = "${var.project}-${var.environment}-ngw-ip"
    environment = var.environment
    project = var.project
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.eks-public[0].id

  tags = {
    Name = "${var.project}-${var.environment}-ngw"
    environment = var.environment
    project = var.project
  }
}

# Add route to route table
resource "aws_route" "main" {
  route_table_id         = aws_vpc.eks-vpc.default_route_table_id
  nat_gateway_id         = aws_nat_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}

# Security group for public subnet
resource "aws_security_group" "eks_public_sg" {
  name   = "${var.project}-${var.environment}-Public-sg"
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    Name = "${var.project}-${var.environment}-Public-sg"
    environment = var.environment
    project = var.project
  }
}

# Security group traffic rules
resource "aws_security_group_rule" "sg_ingress_public_443" {
  security_group_id = aws_security_group.eks_public_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_ingress_public_80" {
  security_group_id = aws_security_group.eks_public_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_egress_public" {
  security_group_id = aws_security_group.eks_public_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security group for data plane
resource "aws_security_group" "data_plane_sg" {
  name   = "${var.project}-${var.environment}-Worker-sg"
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    Name = "${var.environment}-Worker-sg"
    environemnt = var.environment
    project = var.project

  }
}

# Security group traffic rules
resource "aws_security_group_rule" "nodes" {
  description       = "Allow nodes to communicate with each other"
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = flatten([cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 0), cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 1), cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 3)])
}

resource "aws_security_group_rule" "nodes_inbound" {
  description       = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = flatten([cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 3)])
  # cidr_blocks       = flatten([var.private_subnet_cidr_blocks])
}

resource "aws_security_group_rule" "node_outbound" {
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security group for control plane
resource "aws_security_group" "control_plane_sg" {
  name   = "${var.project}-${var.environment}-ControlPlane-sg"
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    Name = "${var.project}-${var.environment}-ControlPlane-sg"
    environment = var.environment
    project = var.project
  }
}

# Security group traffic rules
resource "aws_security_group_rule" "control_plane_inbound" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = flatten([cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 0), cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 1), cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.eks_vpc_cidr, var.subnet_cidr_bits, 3)])
  # cidr_blocks       = flatten([var.private_subnet_cidr_blocks, var.public_subnet_cidr_blocks])
}

resource "aws_security_group_rule" "control_plane_outbound" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

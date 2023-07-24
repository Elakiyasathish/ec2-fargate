# EKS Cluster
resource "aws_eks_cluster" "demo_eks_cluster" {
  name     = "${var.project}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.25"

  vpc_config {
    # security_group_ids      = [aws_security_group.eks_cluster.id, aws_security_group.eks_nodes.id] # already applied to subnet
    subnet_ids              = flatten([aws_subnet.eks-public[*].id, aws_subnet.eks-private[*].id])
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-cluster"
    environment = var.environment
    project = var.project
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}


# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.project}-${var.environment}-Cluster-Role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}


# EKS Cluster Security Group
resource "aws_security_group" "demo_eks_clusterSG" {
  name        = "${var.project}-${var.environment}-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.eks-vpc.id


  tags = {
    Name = "${var.project}-${var.environment}-cluster-sg"
    environment = var.environment
    project = var.project
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.demo_eks_clusterSG.id
  to_port                  = 443
  type                     = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.demo_eks_clusterSG.id
  to_port                  = 65535
  type                     = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}

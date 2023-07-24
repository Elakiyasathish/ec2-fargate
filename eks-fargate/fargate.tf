# Fargate Profile
resource "aws_eks_fargate_profile" "demo_fargate_profile" {
  cluster_name = aws_eks_cluster.demo_eks_cluster.name
  fargate_profile_name = "${var.project}-${var.environment}-fargate-profile"  # Change this to your desired Fargate profile name
  pod_execution_role_arn = aws_iam_role.fargate_profile.arn

  subnet_ids = aws_subnet.eks-private[*].id  # Use the private subnets for Fargate profile

  selector {
    namespace = var.kubernetes_namespace  # Replace with the namespace(s) you want to use Fargate for
  }
  
  # Add more namespace selectors if needed, e.g., for kube-system or other namespaces

  tags = {
    Name = "${var.project}-${var.environment}-fargate-profile"
    environment = var.environment
    project = var.project
  }
}

# Fargate Profile IAM Role
resource "aws_iam_role" "fargate_profile" {
  name = "${var.project}-${var.environment}-Fargate-Profile-Role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_profile_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_profile.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.fargate_profile.name
}


resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.fargate_profile.name
}


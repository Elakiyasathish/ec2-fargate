output "cluster_name" {
  value = aws_eks_cluster.demo_eks_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.demo_eks_cluster.endpoint
}
output "node_group_name" {
  value = aws_eks_node_group.demo_node_group.node_group_name
}

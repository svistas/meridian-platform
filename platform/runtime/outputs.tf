output "cluster_name" {
  value = aws_eks_cluster.session.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.session.endpoint
}

output "cluster_security_group_id" {
  description = "Every node and pod sits in this group. Path 01 datastores accept connections from it."
  value       = aws_eks_cluster.session.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "kubeconfig_command" {
  description = "Run this to talk to the session cluster."
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.session.name} --region ${var.region}"
}

output "datastores_reachable" {
  description = "Path 01 datastores the cluster can connect to."
  value       = data.aws_security_groups.datastores.ids
}

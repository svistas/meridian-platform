# The session cluster.
#
# The control plane costs USD 0.10 an hour whether or not anything is running
# on it, which is the whole reason this stack exists separately from the
# bootstrap (ADR-0006).

resource "aws_eks_cluster" "session" {
  name     = "meridian-session"
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = var.private_subnet_ids

    # Public endpoint with IAM authentication. GitHub-hosted runners have no
    # fixed addresses, so a private endpoint would need a self-hosted runner or
    # a tunnel. Known debt; Production Readiness makes it private and moves to
    # pull-based GitOps (ADR-0006).
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  access_config {
    # Access entries only. No aws-auth ConfigMap to drift.
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Control plane logs. "api" and "authenticator" answer who did what to the
  # cluster; the rest are noisy and billed per GB ingested.
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = {
    Name = "meridian-session"
  }

  # The log group must exist before the cluster, or EKS creates it on first
  # log delivery with no retention and Terraform's own log group then fails to
  # create. Declaring it is not enough -- without this, the two race.
  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.cluster,
  ]
}

# Control plane logs land in a log group AWS creates implicitly with no
# retention. Creating it first fixes that, the same lesson as path 01.
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/meridian-session/cluster"
  retention_in_days = 7
}

resource "aws_eks_node_group" "session" {
  cluster_name    = aws_eks_cluster.session.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  # Spot, and ARM. A session is interruptible by definition: if a node is
  # reclaimed the cluster replaces it, and the worst case is redeploying.
  #
  # Several types rather than one: a single type means a single spot pool, and
  # when that pool is short the node group cannot launch anything at all. With
  # four, EKS moves to the next pool instead of leaving the session without
  # nodes. They are all ARM, matching the AMI type below, and all small enough
  # that the worst case is a few cents an hour more than the best.
  capacity_type  = "SPOT"
  instance_types = var.node_instance_types
  ami_type       = "AL2023_ARM_64_STANDARD"
  disk_size      = 20

  scaling_config {
    desired_size = var.node_count
    min_size     = var.node_count
    max_size     = var.node_count
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "meridian.health/lifecycle" = "session"
  }

  # Nodes cannot register without a route to the internet.
  depends_on = [
    aws_iam_role_policy_attachment.node,
    aws_route_table_association.private,
    aws_nat_gateway.session,
  ]
}

# Add-ons. Versions are resolved by EKS for the cluster version rather than
# pinned: a session cluster is recreated constantly, and a stale pin would
# break it silently.
resource "aws_eks_addon" "core" {
  for_each = toset(["vpc-cni", "kube-proxy", "coredns", "eks-pod-identity-agent"])

  cluster_name                = aws_eks_cluster.session.name
  addon_name                  = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # coredns needs somewhere to run.
  depends_on = [aws_eks_node_group.session]
}

# Container logs to CloudWatch. The agent gets its own identity through Pod
# Identity rather than borrowing the node role.
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = aws_eks_cluster.session.name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  pod_identity_association {
    role_arn        = aws_iam_role.cloudwatch_observability.arn
    service_account = "cloudwatch-agent"
  }

  # Container Insights metrics are billed per metric and are not what the
  # guarantee asks for; logs are. Keep the agent to log collection.
  configuration_values = jsonencode({
    containerLogs = { enabled = true }
    agent = {
      config = {
        logs = {
          metrics_collected = {
            kubernetes = {
              enhanced_container_insights = false
            }
          }
        }
      }
    }
  })

  depends_on = [aws_eks_addon.core]
}

# CI deploys with Helm, so the apply role needs to reach the cluster API.
# Cluster-admin is more than it needs: narrowing this to a namespace-scoped
# policy is listed as debt in ADR-0006.
resource "aws_eks_access_entry" "ci_apply" {
  cluster_name  = aws_eks_cluster.session.name
  principal_arn = var.ci_apply_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ci_apply" {
  cluster_name  = aws_eks_cluster.session.name
  principal_arn = var.ci_apply_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ci_apply]
}

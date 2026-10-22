# Roles the cluster and its nodes assume. These are cheap and specific to the
# session stack, so they are created and destroyed with it.

data "aws_iam_policy_document" "assume" {
  for_each = toset(["eks.amazonaws.com", "ec2.amazonaws.com"])

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [each.value]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "meridian-session-cluster"
  description        = "EKS control plane for the path 02 session cluster"
  assume_role_policy = data.aws_iam_policy_document.assume["eks.amazonaws.com"].json
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node" {
  name               = "meridian-session-node"
  description        = "Nodes in the path 02 session cluster"
  assume_role_policy = data.aws_iam_policy_document.assume["ec2.amazonaws.com"].json
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    # Nodes pull service images from the ECR repositories path 02 creates.
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    # Required for Systems Manager access to a node when something needs
    # debugging; there is no SSH key and no public address.
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# The CloudWatch agent runs as a pod and gets its own identity, not the node's.
resource "aws_iam_role" "cloudwatch_observability" {
  name        = "meridian-session-cloudwatch"
  description = "CloudWatch agent add-on, through EKS Pod Identity"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_observability" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

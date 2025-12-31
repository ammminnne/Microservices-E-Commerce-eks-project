provider "aws" {
  region = "us-east-1"
}

# 1. On récupère le VPC par défaut
data "aws_vpc" "default" {
  default = true
}

# 2. On récupère les sous-réseaux VALIDES (On force les zones a, b, c, d uniquement)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    # IMPORTANT : On liste explicitement les zones qui marchent (on évite us-east-1e)
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  }
}

# 3. On récupère le "LabRole" existant
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# 4. Création du Cluster EKS
resource "aws_eks_cluster" "eks" {
  name     = "project-eks"
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }
}

# 5. Création des Workers (Node Group)
resource "aws_eks_node_group" "node_grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "project-node-group"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
}

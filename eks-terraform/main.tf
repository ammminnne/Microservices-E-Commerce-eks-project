provider "aws" {
  region = "us-east-1"
}

# 1. On récupère le VPC par défaut (votre environnement Lab)
data "aws_vpc" "default" {
  default = true
}

# 2. On récupère les sous-réseaux du Lab
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 3. CRUCIAL : On récupère le "LabRole" existant au lieu d'en créer un
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# 4. Création du Cluster EKS
resource "aws_eks_cluster" "eks" {
  name     = "project-eks"
  # On utilise le LabRole ici
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }
}

# 5. Création des Workers (Node Group)
resource "aws_eks_node_group" "node_grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "project-node-group"
  # On utilise encore le LabRole ici
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  # t3.medium est plus stable pour les Labs que t2.large
  instance_types = ["t3.medium"]
}

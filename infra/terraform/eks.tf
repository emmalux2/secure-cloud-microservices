module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name    = "secure-cloud-cluster-v2"
  cluster_version = "1.34"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      min_capacity     = 2
      max_capacity     = 4
      instance_types   = ["t3.medium"]
    }
  }
}

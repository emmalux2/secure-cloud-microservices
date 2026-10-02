module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name                    = "secure-cloud-cluster-v2"
  cluster_version                 = "1.34"
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Grant your GitHub Actions role admin access to the Kubernetes API
  access_entries = {
    github_actions = {
      principal_arn = "arn:aws:iam::797776210271:role/SecureCloudGitHubActionsRole"
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      instance_types = ["t3.medium"]
    }
  }
}

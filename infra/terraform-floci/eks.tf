
module "eks" {
  source = "./modules/eks"

  cluster_name                             = "secure-cloud-cluster-v2"
  cluster_version                          = "1.34"
  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = true
  cluster_endpoint_public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  enable_cluster_creator_admin_permissions = false
  enable_irsa                              = var.enable_auth_service_irsa

  vpc_id                        = module.vpc.vpc_id
  subnet_ids                    = module.vpc.private_subnets
  create_cluster_security_group = false
  cluster_security_group_id     = module.vpc.default_security_group_id
  create_node_security_group    = false
  node_security_group_id        = module.vpc.default_security_group_id

  # LocalStack does not implement the EKS access-entry API.
  access_entries = {}

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      instance_types = ["t3.medium"]
    }
  }
}

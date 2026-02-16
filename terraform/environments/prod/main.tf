module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
}

module "eks" {
  source       = "../../modules/eks"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}

module "security" {
  source       = "../../modules/security"
  cluster_name = module.eks.cluster_name

  depends_on = [module.eks]
}


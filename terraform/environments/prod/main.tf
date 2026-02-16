module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
}

module "eks" {
  source       = "../../modules/eks"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids
}

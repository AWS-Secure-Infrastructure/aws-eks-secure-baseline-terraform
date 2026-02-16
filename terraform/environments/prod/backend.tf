terraform {
  backend "s3" {
    bucket = "REPLACE_WITH_STATE_BUCKET"
    key    = "eks-secure-baseline/prod/terraform.tfstate"
    region = "eu-central-1"
  }
}

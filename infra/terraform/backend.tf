terraform {
  backend "s3" {
    bucket       = "my-terraform-state-ansy"
    key          = "secure-cloud-microservices/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
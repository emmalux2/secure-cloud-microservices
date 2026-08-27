terraform {
  backend "s3" {
    bucket       = "secure-cloud-microservices-tfstate-797776210271"
    key          = "secure-cloud-microservices/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
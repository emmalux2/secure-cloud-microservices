terraform {
  backend "s3" {
    bucket         = "secure-cloud-microservices-tfstate-797776210271"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "secure-cloud-tf-locks" # or use_lockfile = true if you want to drop DynamoDB
    encrypt        = true
  }
}

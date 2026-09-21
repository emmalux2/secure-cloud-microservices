resource "aws_kms_key" "eks" {
  description         = "KMS key for Secure Cloud EKS and WAF logging"
  enable_key_rotation = true

  tags = {
    Name = "secure-cloud-eks-kms"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/secure-cloud-eks"
  target_key_id = aws_kms_key.eks.key_id
}
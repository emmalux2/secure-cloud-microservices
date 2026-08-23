resource "aws_secretsmanager_secret" "jwt_access" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation will be configured when rotation Lambda is deployed
  name                    = "secure-cloud/jwt-access-secret"
  kms_key_id              = aws_kms_key.eks.arn
  recovery_window_in_days = 0
}

resource "random_password" "jwt_access" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret_version" "jwt_access" {
  secret_id     = aws_secretsmanager_secret.jwt_access.id
  secret_string = random_password.jwt_access.result
}

data "aws_iam_policy_document" "auth_service_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}

resource "aws_iam_role" "auth_service_irsa" {
  name               = "auth-service-irsa"
  assume_role_policy = data.aws_iam_policy_document.auth_service_trust.json
}

resource "aws_iam_role_policy" "auth_service_secrets_access" {
  name = "auth-service-secrets-read"
  role = aws_iam_role.auth_service_irsa.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [aws_secretsmanager_secret.jwt_access.arn]
    }]
  })
}
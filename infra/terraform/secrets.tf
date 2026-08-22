resource "aws_secretsmanager_secret" "jwt_access" {
  name = "secure-cloud/jwt-access-secret"
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

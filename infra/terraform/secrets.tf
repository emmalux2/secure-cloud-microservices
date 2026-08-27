# ============================================================
# EXISTING JWT SECRET
# ============================================================
# This secret already exists in AWS Secrets Manager.
# Terraform will READ the existing secret instead of creating it.

data "aws_secretsmanager_secret" "jwt_access" {
  name = "secure-cloud/jwt-access-secret"
}


# ============================================================
# AUTH SERVICE IRSA TRUST POLICY
# ============================================================

data "aws_iam_policy_document" "auth_service_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}


# ============================================================
# AUTH SERVICE IRSA ROLE
# ============================================================

resource "aws_iam_role" "auth_service_irsa" {
  name               = "auth-service-irsa"
  assume_role_policy = data.aws_iam_policy_document.auth_service_trust.json
}


# ============================================================
# ALLOW AUTH SERVICE TO READ JWT SECRET
# ============================================================

resource "aws_iam_role_policy" "auth_service_secrets_access" {
  name = "auth-service-secrets-read"
  role = aws_iam_role.auth_service_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = [
          data.aws_secretsmanager_secret.jwt_access.arn
        ]
      }
    ]
  })
}
# ============================================================
# EXISTING JWT SECRET
# ============================================================
# The secret already exists in AWS Secrets Manager.
# Terraform only reads the existing secret.
# Terraform will NOT create or delete this secret.

data "aws_secretsmanager_secret" "jwt_access" {
  name = "secure-cloud/jwt-access-secret"
}


# ============================================================
# AUTH SERVICE IRSA TRUST POLICY
# ============================================================
# Allows the Kubernetes service account running the auth
# service to assume the IAM role through the EKS OIDC provider.

data "aws_iam_policy_document" "auth_service_trust" {
  statement {
    effect  = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
  }
}


# ============================================================
# AUTH SERVICE IRSA ROLE
# ============================================================

resource "aws_iam_role" "auth_service_irsa" {
  name = "auth-service-irsa"

  assume_role_policy = data.aws_iam_policy_document.auth_service_trust.json
}


# ============================================================
# ALLOW AUTH SERVICE TO READ JWT SECRET
# ============================================================
# The auth service can retrieve the secret value from
# AWS Secrets Manager.
#
# Terraform does NOT manage the secret itself.
# Terraform only manages the IAM permission that allows
# the auth service to read it.

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

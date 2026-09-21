# ============================================================
# JWT SECRET
# ============================================================
# Terraform creates and manages this secret.
# terraform destroy will delete the secret as well.
#
# IMPORTANT:
# The actual JWT secret value should be supplied separately.
# Do not hard-code the secret value in this file.

resource "aws_secretsmanager_secret" "jwt_access" {
  name        = "secure-cloud/jwt-access-secret"
  description = "JWT access secret for Secure Cloud microservices"

  tags = {
    Project = "secure-cloud-microservices"
  }
}


# ============================================================
# AUTH SERVICE IRSA TRUST POLICY
# ============================================================
# Allows the Kubernetes service account running the auth
# service to assume the IAM role through the EKS OIDC provider.

data "aws_iam_policy_document" "auth_service_trust" {
  statement {
    effect = "Allow"

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
# AWS Secrets Manager through its Kubernetes IRSA role.
#
# Terraform manages the secret AND the IAM permission.

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
          aws_secretsmanager_secret.jwt_access.arn
        ]
      }
    ]
  })
}
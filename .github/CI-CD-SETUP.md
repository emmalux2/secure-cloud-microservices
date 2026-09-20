# CI/CD Bootstrap

The deployment workflow uses GitHub Actions OIDC. It does not use `aws configure`, long-lived access keys, or repository AWS secrets.

## One-time AWS setup

Create an IAM OIDC provider for:

```text
https://token.actions.githubusercontent.com
```

Use audience `sts.amazonaws.com` and the GitHub Actions root certificate thumbprint required by AWS. Create a production IAM role trusted by that provider. Because the deployment job uses the `production` environment, restrict the trust policy to that environment:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<OWNER>/<REPOSITORY>:environment:production"
        }
      }
    }
  ]
}
```

Attach the least-privilege policy needed for the resources in `infra/terraform`, ECR image publishing, EKS access, and Helm deployment. The role also needs access to the Terraform S3 backend and its lockfile.

Create a separate read-only planning role for pull requests. Its trust policy should use the same OIDC provider and audience, but the subject must be the `plan` environment:

```text
repo:<OWNER>/<REPOSITORY>:environment:plan
```

Do not give the pull-request role permission to apply infrastructure, modify IAM, or deploy to EKS.

## One-time GitHub setup

Create a protected GitHub environment named `production`. Add this environment variable:

```text
AWS_ROLE_ARN=arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsDeployRole
```

Require approval for `production` if applies must be reviewed before changing AWS.

Create a second environment named `plan` and add this environment variable:

```text
AWS_ROLE_ARN=arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsPlanRole
```

Pull requests use `plan`; pushes to `main` and manual runs use `production`. These are GitHub environment variables, not GitHub secrets. The application JWT remains in AWS Secrets Manager under `secure-cloud/jwt-access-secret`.

## Workflow behavior

- Pull requests run Terraform format, init, validate, and plan.
- Pushes to `main` and manual runs apply Terraform.
- After Terraform succeeds, the workflow builds both services and pushes commit-tagged images to ECR.
- It deploys the application Helm chart to EKS.
- It installs or upgrades `kube-prometheus-stack` and applies the ServiceMonitor and PrometheusRule resources.

The S3 backend bucket and the Secrets Manager secret referenced by Terraform must exist before the first run. The EKS cluster must have the EBS CSI driver and a `gp3` StorageClass before persistent monitoring storage can bind.

## Teardown

Use the manually triggered `Destroy SecureCloud Infrastructure` workflow when the environment should be removed:

1. Open **Actions** and select `Destroy SecureCloud Infrastructure`.
2. Select **Run workflow** and choose the `production` environment.
3. Type `DESTROY` exactly in the confirmation field.
4. Approve the protected environment if approval is enabled.

The workflow runs a Terraform destroy plan, destroys Terraform-managed infrastructure, removes the ECR repositories, and permanently deletes `secure-cloud/jwt-access-secret`. It intentionally keeps the Terraform S3 state bucket so the destroy state remains available. The KMS key uses a seven-day deletion window, so it may remain scheduled for deletion during that period.
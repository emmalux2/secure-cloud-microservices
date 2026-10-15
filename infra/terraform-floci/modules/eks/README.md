# Floci EKS module

This is a local copy of `terraform-aws-modules/eks/aws` v20.24.0, used by the
Floci practice configuration. Local compatibility changes ignore `access_config`,
`encryption_config`, and `enabled_cluster_log_types`. LocalStack omits
`access_config` and logging state from EKS cluster responses, which otherwise
causes unnecessary cluster replacement or unsupported logging updates. It does
not implement `AssociateEncryptionConfig`, so managing `encryption_config`
causes an API error. These workarounds keep the existing cluster and avoid
unsupported API calls.

The production AWS configuration continues to use the upstream module directly.

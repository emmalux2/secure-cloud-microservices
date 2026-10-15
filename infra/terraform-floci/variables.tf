variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}


variable "github_actions_role_arn" {
  description = "Reserved for AWS EKS access configuration; Floci does not implement EKS access entries"
  type        = string
  default     = ""
}

variable "enable_auth_service_irsa" {
  description = "Enable auth-service IRSA only when the EKS endpoint exposes an OIDC issuer"
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Allowed IPv4 CIDR ranges for the EKS public API endpoint"
  type        = list(string)
  default     = ["127.0.0.1/32"]
}

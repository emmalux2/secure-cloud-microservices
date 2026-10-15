output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "auth_service_role_arn" {
  description = "IAM role ARN for the auth-service Kubernetes service account"
  value       = aws_iam_role.auth_service_irsa.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller"
  value       = aws_iam_role.load_balancer_controller.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the Web ACL applied to the application ALB"
  value       = aws_wafv2_web_acl.main.arn
}

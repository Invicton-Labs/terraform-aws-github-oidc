output "oidc_host" {
  description = "The OIDC host that the IAM OIDC provider trusts."
  value       = local.oidc_host
}

output "oidc_provider" {
  description = "The IAM OIDC provider that was created."
  value       = aws_iam_openid_connect_provider.github_oidc
}

output "audience" {
  description = "The audience used by the IAM OIDC provider."
  value       = var.audience
}

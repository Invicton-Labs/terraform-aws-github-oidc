//==================================================
//     Outputs that match the input variables
//==================================================
output "repository_roles" {
  description = "The value of the `repository_roles` input variable, or the default value if the input was `null` or wasn't provided."
  value       = var.repository_roles
}
output "add_unique_suffix_to_role_names" {
  description = "The value of the `add_unique_suffix_to_role_names` input variable, or the default value if the input was `null` or wasn't provided."
  value       = var.add_unique_suffix_to_role_names
}
output "add_unique_suffix_to_policy_names" {
  description = "The value of the `add_unique_suffix_to_policy_names` input variable, or the default value if the input was `null` or wasn't provided."
  value       = var.add_unique_suffix_to_policy_names
}
output "iam_oidc_provider_module" {
  description = "The value of the `iam_oidc_provider_module` input variable."
  value       = var.iam_oidc_provider_module
}

//==================================================
//       Outputs generated by this module
//==================================================
output "iam_roles" {
  description = "A map of role names to `aws_iam_role` resources."
  value = {
    for role in aws_iam_role.this :
    role.name => role
  }
}

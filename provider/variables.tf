variable "audience" {
  description = "The audience value that will be used in the OIDC requests from GitHub Actions. Leave as the default if you're using the official AWS authentication action (https://github.com/aws-actions/configure-aws-credentials)."
  type        = string
  default     = "sts.amazonaws.com"
  nullable    = false
}

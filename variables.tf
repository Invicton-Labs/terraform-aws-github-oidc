variable "repository_roles" {
  description = <<EOF
  A map of role names to repository permission configurations.

  `repositories`: A list of repositories, in ORG/REPO format, that should be able to assume the role. At least one value MUST be provided, and the repository making the request MUST be in this list. NOTE: these strings use the same wildcard format as AWS IAM policies; `?` will be considered a single-character wildcard and  `*` will be considered a multi-characer wildcard.

  `branches`: If the GitHub Actions job was triggered by a push to a branch, that branch must be in this list.

  `tags`: If the GitHub Actions job GitHub Actions job was triggered by a push of a new tag, that tag must be in this list.

  `environments`: If the GitHub Actions job was triggered by a push to a GitHub Environment, that environment must be in this list.

  `pull_requests`: Set to `true` if GitHub Actions jobs triggered by pull requests should be permitted to access these credentials.

  `iam_policy_arns`: A list of ARNs of IAM policies that should be attached to the role.

  `iam_policy_documents`: A list of objects, each with a policy name and a JSON-encoded IAM policy document, that should be used to create IAM policies, which will then be attached to the role.

  `iam_inline_policy_documents`: A list of objects, each with a policy name and a JSON-encoded IAM policy document, that will be inline-attached to the role.

  `max_session_duration`: Maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours.

  `additional_role_trust_policy_documents`: A list of additional JSON-encoded IAM trust policy documents to include in the trust policy for the role. This is useful if you want the role to be assumable by additional entities other than GitHub Actions.
EOF
  type = list(object({
    role_name       = string
    repositories    = list(string)
    branches        = list(string)
    tags            = list(string)
    environments    = list(string)
    pull_requests   = bool
    iam_policy_arns = list(string)
    iam_policy_documents = list(object({
      policy_name     = string
      policy_document = string
    }))
    iam_inline_policy_documents = list(object({
      policy_name     = string
      policy_document = string
    }))
    max_session_duration                   = number
    additional_role_trust_policy_documents = list(string)
  }))
  default  = []
  nullable = false
}

variable "audience" {
  description = "The audience value that will be used in the OIDC requests from GitHub Actions. Leave as the default if you're using the official AWS authentication action."
  type        = string
  default     = "sts.amazonaws.com"
  nullable    = false
}

variable "iam_oidc_provider_arn" {
  description = "The ARN of an existing IAM GitHub Actions OIDC provider. If provided, it will be used instead of creating a new one."
  type        = string
  default     = null
}

variable "add_unique_suffix_to_role_names" {
  description = "Whether to add unique suffixes to role names. Can be useful when renaming roles to prevent conflicts."
  type        = bool
  default     = false
  nullable    = false
}

variable "add_unique_suffix_to_policy_names" {
  description = "Whether to add unique suffixes to policy names. Can be useful when renaming policies to prevent conflicts."
  type        = bool
  default     = false
  nullable    = false
}

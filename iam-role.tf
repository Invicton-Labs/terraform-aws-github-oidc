locals {
  assume_actions = [
    "sts:AssumeRoleWithWebIdentity"
  ]
  federation_identifiers = [
    var.iam_oidc_provider_module.oidc_provider.arn
  ]
  audiences = [
    var.iam_oidc_provider_module.audience
  ]
  role_refs = [
    for role_config in var.repository_roles :
    [
      for ref in concat(
        [
          for branch in(role_config.branches != null ? role_config.branches : []) :
          "ref:refs/heads/${branch}"
        ],
        [
          for tag in(role_config.tags != null ? role_config.tags : []) :
          "ref:refs/tags/${tag}"
        ],
        [
          for env in(role_config.environments != null ? role_config.environments : []) :
          "environment:${env}"
        ],
        role_config.pull_requests ? ["pull_request"] : []
      ) :
      "repo:*:${ref}"
    ]
  ]
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "trust" {
  count = length(var.repository_roles)

  // Include any additional trust policy documents
  source_policy_documents = var.repository_roles[count.index].additional_role_trust_policy_documents != null ? var.repository_roles[count.index].additional_role_trust_policy_documents : []

  // Always allow the owner account to assume the role (this just allows granting
  // other users/roles permissions to assume it)
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }

  // Allow the role assumption if basic criteria are met
  statement {
    effect  = "Allow"
    actions = local.assume_actions
    principals {
      type        = "Federated"
      identifiers = local.federation_identifiers
    }

    // Ensure that it has the intended audience
    condition {
      variable = "${var.iam_oidc_provider_module.oidc_host}:aud"
      test     = "StringEquals"
      values   = local.audiences
    }

    // Ensure that the request came from an accepted repository
    condition {
      variable = "${var.iam_oidc_provider_module.oidc_host}:sub"
      test     = "StringLike"
      values = [
        for repo in var.repository_roles[count.index].repositories :
        "repo:${repo}:*"
      ]
    }
  }

  statement {
    effect  = "Deny"
    actions = local.assume_actions
    principals {
      type        = "Federated"
      identifiers = local.federation_identifiers
    }
    // If there are no refs specified, always deny.
    // If refs are specified, deny if the sub doesn't
    // match at least one of them.
    dynamic "condition" {
      for_each = length(local.role_refs[count.index]) > 0 ? [local.role_refs[count.index]] : []
      content {
        variable = "${var.iam_oidc_provider_module.oidc_host}:sub"
        test     = "StringNotLike"
        values   = condition.value
      }
    }
  }
}

resource "aws_iam_role" "this" {
  count                = length(var.repository_roles)
  name                 = var.add_unique_suffix_to_role_names ? null : var.repository_roles[count.index].role_name
  name_prefix          = var.add_unique_suffix_to_role_names ? "${var.repository_roles[count.index].role_name}-" : null
  assume_role_policy   = data.aws_iam_policy_document.trust[count.index].json
  max_session_duration = var.repository_roles[count.index].max_session_duration
}

locals {
  existing_policy_attachments = concat([
    for rr_idx, rr in var.repository_roles :
    [
      for arn in rr.iam_policy_arns != null ? rr.iam_policy_arns : [] :
      {
        rr_idx     = rr_idx
        policy_arn = arn
      }
    ]
  ]...)

  num_new_policies = sum([
    for rr in var.repository_roles :
    rr.iam_policy_documents == null ? 0 : length(rr.iam_policy_documents)
  ])

  new_policies = concat([
    for rr_idx, rr in var.repository_roles :
    [
      for policy_config in rr.iam_policy_documents != null ? rr.iam_policy_documents : [] :
      {
        rr_idx   = rr_idx
        name     = policy_config.policy_name
        document = policy_config.policy_document
      }
    ]
  ]...)

  num_inline_policies = sum([
    for rr in var.repository_roles :
    rr.iam_inline_policy_documents == null ? 0 : length(rr.iam_inline_policy_documents)
  ])

  inline_policies = concat([
    for rr_idx, rr in var.repository_roles :
    [
      for policy_config in rr.iam_inline_policy_documents != null ? rr.iam_inline_policy_documents : [] :
      {
        rr_idx   = rr_idx
        name     = policy_config.policy_name
        document = policy_config.policy_document
      }
    ]
  ]...)
}

resource "aws_iam_role_policy_attachment" "existing" {
  count      = length(local.existing_policy_attachments)
  role       = aws_iam_role.this[local.existing_policy_attachments[count.index].rr_idx].name
  policy_arn = local.existing_policy_attachments[count.index].policy_arn
}

resource "aws_iam_policy" "new" {
  count       = local.num_new_policies
  name        = var.add_unique_suffix_to_policy_names ? null : local.new_policies[count.index].name
  name_prefix = var.add_unique_suffix_to_policy_names ? "${local.new_policies[count.index].name}-" : null
  policy      = local.new_policies[count.index].document
}

resource "aws_iam_role_policy_attachment" "new" {
  count      = local.num_new_policies
  role       = aws_iam_role.this[local.new_policies[count.index].rr_idx].name
  policy_arn = aws_iam_policy.new[count.index].arn
}

resource "aws_iam_role_policy" "inline" {
  count       = local.num_inline_policies
  role        = aws_iam_role.this[local.inline_policies[count.index].rr_idx].name
  name        = var.add_unique_suffix_to_policy_names ? null : local.inline_policies[count.index].name
  name_prefix = var.add_unique_suffix_to_policy_names ? "${local.inline_policies[count.index].name}-" : null
  policy      = local.inline_policies[count.index].document
}

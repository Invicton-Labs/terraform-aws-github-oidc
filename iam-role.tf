data "aws_iam_policy_document" "trust" {
  count = length(var.repository_roles)

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Federated"
      identifiers = [
        "token.actions.githubusercontent.com"
      ]
    }

    // Ensure that it has the intended audience
    condition {
      variable = "token.actions.githubusercontent.com:aud"
      test     = "StringEquals"
      values = [
        "sts.amazonaws.com"
      ]
    }

    // Ensure that the request came from an accepted repository
    condition {
      variable = "token.actions.githubusercontent.com:sub"
      test     = "StringLike"
      values = [
        for repo in var.repository_roles[count.index].repositories :
        "repo:${repo}:*"
      ]
    }

    // Ensure that the ref is allowed
    condition {
      variable = "token.actions.githubusercontent.com:sub"
      test     = "StringLike"
      values = [
        for ref in concat(
          [
            for branch in(var.repository_roles[count.index].branches != null ? var.repository_roles[count.index].branches : []) :
            "ref:refs/heads/${branch}"
          ],
          [
            for tag in(var.repository_roles[count.index].tags != null ? var.repository_roles[count.index].tags : []) :
            "ref:refs/tags/${tag}"
          ],
          [
            for env in(var.repository_roles[count.index].environments != null ? var.repository_roles[count.index].environments : []) :
            "environment:${env}"
          ],
          var.repository_roles[count.index].pull_requests ? ["pull_request"] : []
        ) :
        "repo:*/*:${ref}"
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  count              = length(var.repository_roles)
  name               = var.add_unique_suffix_to_role_names ? null : var.repository_roles[count.index].role_name
  name_prefix        = var.add_unique_suffix_to_role_names ? "${var.repository_roles[count.index].role_name}-" : null
  assume_role_policy = data.aws_iam_policy_document.trust[count.index].json
}

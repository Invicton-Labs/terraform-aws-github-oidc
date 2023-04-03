resource "aws_ssm_parameter" "parameters" {
  count = length(var.repository_roles)
  name  = "/github/${var.repository_roles[count.index].role_name}"
  type  = "SecureString"
  value = jsonencode(var.repository_roles[count.index].workflow_parameters)
}

data "aws_iam_policy_document" "parameters" {
  count = length(var.repository_roles)
  statement {
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      aws_ssm_parameter.parameters[count.index].arn
    ]
  }
}

// Allow the role to read the SSM parameter
resource "aws_iam_role_policy" "parameters" {
  count       = length(var.repository_roles)
  role        = aws_iam_role.this[count.index].name
  name        = var.add_unique_suffix_to_policy_names ? null : "read-ssm-parameter"
  name_prefix = var.add_unique_suffix_to_policy_names ? "read-ssm-parameter-" : null
  policy      = data.aws_iam_policy_document.parameters[count.index].json
}

module "existing_provider" {
  source  = "Invicton-Labs/input-provided/null"
  version = "~>0.1.1"
  input   = var.existing_provider
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  count = module.existing_provider.one_if_not_provided
  url   = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = []
}

data "aws_iam_openid_connect_provider" "github_oidc" {
  count = module.existing_provider.one_if_provided
  arn   = var.existing_provider.arn
}

locals {
  oidc_provider = module.existing_provider.provided ? data.aws_iam_openid_connect_provider.github_oidc[0] : aws_iam_openid_connect_provider.github_oidc[0]
}

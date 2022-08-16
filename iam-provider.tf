module "existing_provider" {
  source  = "Invicton-Labs/input-provided/null"
  version = "~>0.1.1"
  input   = var.iam_oidc_provider_arn
}

locals {
  provider_url    = "https://${local.oidc_host}"
  oidc_config_url = "${local.provider_url}/.well-known/openid-configuration"
}

data "http" "github_oidc_config" {
  count = module.existing_provider.one_if_not_provided
  url   = local.oidc_config_url
  request_headers = {
    Accept = "application/json"
  }
}
data "tls_certificate" "github_oidc" {
  count = length(data.http.github_oidc_config)
  url   = jsondecode(data.http.github_oidc_config[0].response_body).jwks_uri
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  count = module.existing_provider.one_if_not_provided
  url   = local.provider_url
  client_id_list = [
    var.audience,
  ]
  thumbprint_list = [
    data.tls_certificate.github_oidc[0].certificates[0].sha1_fingerprint
  ]
}

data "aws_iam_openid_connect_provider" "github_oidc" {
  count = module.existing_provider.one_if_provided
  arn   = var.iam_oidc_provider_arn
}

module "assert_correct_provider_host" {
  count         = module.existing_provider.one_if_provided
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = data.aws_iam_openid_connect_provider.github_oidc[0].url == local.oidc_host
  error_message = "The provider URL of the existing OIDC identity provider (${data.aws_iam_openid_connect_provider.github_oidc[0].url}) does not match the expected value for GitHub OIDC identity providers (${local.oidc_host})."
}

module "assert_correct_provider_audience" {
  count   = module.existing_provider.one_if_provided
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  depends_on = [
    module.assert_correct_provider_host.checked,
  ]
  condition     = contains(data.aws_iam_openid_connect_provider.github_oidc[0].client_id_list, var.audience)
  error_message = "The client_id_list of the existing OIDC identity provider (${join(", ", data.aws_iam_openid_connect_provider.github_oidc[0].client_id_list)}) does not include the value of the `audience` input variable (${var.audience})."
}

locals {
  assertions_checked = length(module.assert_correct_provider_audience) > 0 ? module.assert_correct_provider_audience[0].checked : true
  oidc_provider = local.assertions_checked ? (
    module.existing_provider.provided ? data.aws_iam_openid_connect_provider.github_oidc[0] : aws_iam_openid_connect_provider.github_oidc[0]
  ) : null
}

locals {
  oidc_host       = "token.actions.githubusercontent.com"
  provider_url    = "https://${local.oidc_host}"
  oidc_config_url = "${local.provider_url}/.well-known/openid-configuration"
}

data "http" "github_oidc_config" {
  url = local.oidc_config_url
  request_headers = {
    Accept = "application/json"
  }
}
data "tls_certificate" "github_oidc" {
  url = jsondecode(data.http.github_oidc_config.response_body).jwks_uri
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = local.provider_url
  client_id_list = [
    var.audience,
  ]
  thumbprint_list = [
    data.tls_certificate.github_oidc.certificates[0].sha1_fingerprint
  ]
}

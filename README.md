# Terraform AWS GitHub OIDC

This module creates an IAM OIDC provider for GitHub Actions and associated roles for various repositories, branches, and tags. For technical background on this process, see [these](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect) [pages](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services).


## Multiple Instances

A AWS account can only have a single IAM OIDC provider with a given provider URL. Therefore, if you want to use multiple instances of this module within the same AWS account (in different Terraform configs, or within the same Terraform config), you must pass the ARN of the IAM OIDC provider (the `iam_oidc_provider_arn` output variable) that was created in the first instance of this module as the `iam_oidc_provider_arn` input variable of all other instances of this module.

## Usage

```terraform
module "github_actions_oidc_website" {
  source = "Invicton-Labs/github-oidc/aws"
  repository_roles = [
    // For the dev branch
    {
      role_name = "website-cicd-dev"
      repositories = [
        "Invicton-Labs/website"
      ]
      branches = [
        "dev",
      ]
      tags = null
      environments = null
      pull_requests = false
      iam_policy_arns = null
      iam_policy_documents = [
        {
          policy_name     = "website-dev"
          policy_document = data.aws_iam_policy_document.website_dev.json
        }
      ]
      iam_inline_policy_documents = null
      additional_role_trust_policy_documents = null
    },

    // For the prod branch
    {
      role_name = "website-cicd-prod"
      repositories = [
        "Invicton-Labs/website"
      ]
      branches = [
        "prod",
      ]
      tags = null
      environments = null
      pull_requests = false
      iam_policy_arns = null
      iam_policy_documents = [
        {
          policy_name     = "website-prod"
          policy_document = data.aws_iam_policy_document.website_prod.json
        }
      ]
      iam_inline_policy_documents = null
      additional_role_trust_policy_documents = null
    }
  ]
}
```

And if you wanted to use this same module somewhere else in your configuration:
```terraform

module "github_actions_oidc_api" {
  source = "Invicton-Labs/github-oidc/aws"

  // Pass the IAM OIDC provider ARN in so this module
  // doesn't attempt to create a duplicate (would fail)
  iam_oidc_provider_arn             = module.github_actions_oidc_website.iam_oidc_provider_arn

  repository_roles = [
    // For all branches
    {
      role_name = "api-cicd"
      repositories = [
        "Invicton-Labs/api"
      ]
      branches = [
        "*",
      ]
      tags = null
      environments = null
      pull_requests = false
      iam_policy_arns = null
      iam_policy_documents = [
        {
          policy_name     = "api"
          policy_document = data.aws_iam_policy_document.api.json
        }
      ]
      iam_inline_policy_documents = null
      additional_role_trust_policy_documents = null
    },
  ]
}
```
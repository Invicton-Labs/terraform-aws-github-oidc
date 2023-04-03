# Terraform AWS GitHub OIDC

This module creates an IAM OIDC provider for GitHub Actions and associated roles for various repositories, branches, and tags. For technical background on this process, see [these](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect) [pages](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services).

We will be adding support for additional input arguments for roles (e.g. `path`, `tags`) once Terraform v1.3.0 is released with official support for optional fields in variable objects.


## Multiple Instances

An AWS account can only have a single IAM OIDC provider with a given provider URL. Therefore, we have split this module into two parts: a submodule for creating the IAM provider (can only be used once per AWS account), and the main module for creating repository access (can be used as many times as you like).


## Usage

### Creating the IAM OIDC provider

```terraform
module "github_actions_oidc_provider" {
  // NOTE: there's a double forward slash
  source = "Invicton-Labs/github-oidc/aws//provider"
}
```

### Managing repository access

```terraform
module "github_actions_oidc_website" {
  source = "Invicton-Labs/github-oidc/aws"

  // Pass the module for the provider in its entirety
  iam_oidc_provider_module = module.github_actions_oidc_provider

  // Specify the repository roles
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
      max_session_duration = null
      additional_role_trust_policy_documents = null
      workflow_parameters = {
        myfavouriteparameter = "hello world"
      }
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
      max_session_duration = null
      additional_role_trust_policy_documents = null
      workflow_parameters = {
        myfavouriteparameter = "hello world"
      }
    }
  ]
}
```

### GitHub Actions

For your GitHub Actions workflow, you would then do something like this:

```
name: AWS Credentials Example

on:
  push

env:
  AWS_REGION: "ca-central-1"
  AWS_ACCOUNT_ID: 123456789012

# This permission must be set because, by default, the GitHub token created
# for the workflow doesn't have permission to get an ID token.   
permissions:
  id-token: write

jobs:
  CredsTest:
    runs-on: ubuntu-latest
    steps:
      - name: Clone the repository
        uses: actions/checkout@v3

      # This must be done once in each job that needs AWS credentials
      - name: AWS Config
        id: aws-config
        uses: Invicton-Labs/terraform-aws-github-oidc/action@main
        with:
          region: ${{ env.AWS_REGION }}
          account_id: ${{ env.AWS_ACCOUNT_ID }}
          role_name: website-cicd-${{ github.ref_name }}

      # All future steps IN THE SAME JOB will now use the assumed role,
      # unless different credentials are explicitly provided to that step.
          
      # This will show that we have assumed the role specified above
      - name: Get the caller identity
        run: aws sts get-caller-identity

      # Access one of the `workflow_parameter` values that were set in the Terraform config.
      # This is excellent for passing parameters such as S3 bucket IDs, CloudFront Distribution IDs,
      # and other values that may be necessary in the workflow, without having to set them as 
      # GitHub secrets.
      - name: Show Output Param
        run: echo "${{fromJSON(steps.aws-config.outputs.parameters).myfavouriteparameter}}"
```
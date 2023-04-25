# GitHub Actions Terraform AKS Deployment and Deploying an App to AKS
This project sets up a CI/CD pipeline using GitHub Actions to deploy infrastructure using Terraform and deploy Phonebook Application to that infrastructure.

## Setting Credentials

Terraform needs Azure Credentials to create the infrastructure. We need to provide these values in environment for Terraform to look up.
- ARM_SUBSCRIPTION_ID
- ARM_TENANT_ID
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET

To get these credentials we use this command in a terminal;
```
az ad sp create-for-rbac --sdk-auth --role="Contributor" --scopes="/subscriptions/<subscription_id>"
```

Terraform also needs GitHub Token to create the variables in GitHub repository. We provide the token securely by defining it in the GitHub Actions secrets as `GH_TOKEN`. We assign this value in the pipeline environment section to `GITHUB_TOKEN` with:
```
GITHUB_TOKEN: ${{ secrets.GH_TOKEN }}
```

`az login` and `k8s deployment` use `AZURE_CREDENTIALS` which is also defined as a repo secret.

## Notes

- Since GitHub Actions Pipeline uses an ephemeral agent we need to define a backend to keep our `terraform.tfstate`.
- To use later in the pipeline we define multiple `github_actions_variable`s.
- Since we have our Terraform configuration files in a dedicated folder, we need to define this path in the job environment for the steps which need to access to this folder to run. In a similar fashion we need to define `k8s` path to apply our Kubernetes manifest files.
- Our application needs the ports `30001-30002` open to be accessed. Since the NSG name of the AKS assigned randomly by Azure we assign it to a GitHub variable and add a rule to it in the pipeline.

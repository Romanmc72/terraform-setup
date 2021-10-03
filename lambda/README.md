# Lambda + API Gateway

This directory contains everything packaged together to run a publicly exposed REST API endpoint backed by an AWS Lambda function running off of an ECR container image. You should be able to reference this as a module for other deployments that match this same pattern. The AWS Proxy integration is being used here to pass the sum total of the API Gateway message on to the Lambda function. Your function should handle those requests using an appropriate framework.

In my initial example I deploy a Python container running FastAPI and handling the API Gateway messages via the [Mangum](https://mangum.io/) library. Use whatever floats your boat.

## Running this

You have 2 options to run and deploy this stack.

1. Use `terraform init` and `terraform apply` to apply it straight from this directory.
2. Refer to this code as a module using [Terragrunt](https://terragrunt.gruntwork.io/)

There is an example apply command in `apply.sh` and destroy command in `destroy.sh`. Certain variables are required and there are some that you will use that are different than mine such as the AWS Region and Account ID values. Mine are set as defaults here because this is my code and my project. Override them yourself for your own purposes.

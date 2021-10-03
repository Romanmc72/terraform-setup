##############################################################################
# The Lambda functions that I want to exist and the required parts to get it
# exposed as an API on API Gateway.
##############################################################################

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      environment = var.environment
    }
  }
}

######################################
# Creates the function
######################################

# Function itself
resource "aws_lambda_function" "lambda_function" {
  function_name = var.app_name
  package_type  = "Image"
  image_uri     = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.image_name}:${var.image_tag}"
  role          = aws_iam_role.lambda_role.arn

  environment {
    variables = var.lambda_env_vars
  }
}

# IAM
resource "aws_iam_role" "lambda_role" {
  name = "${var.app_name}-role"
  path = "/service-role/"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

##############################################################################
# API Gateway setup
# There are a TON of pieces to this just to set up a proxy between lambda and
# API Gateway. The hierarchy is like this:
#
# @API (Root Resource)
# |---- {Client} -> @Root Method           -> @Root Integration           -> {Lambda}
# |     {Client} <- @Root Method Response  <- @Root Integration Response  <- {Lambda}
# `- @Proxy Resource
#    `- {Client} -> @Proxy Method          -> @Proxy Integration          -> {Lambda}
#       {Client} <- @Proxy Method Response <- @Proxy Integration Response <- {Lambda}
#
# Then finally the IAM to allow API Gateway to invoke the Lambda and the @Stage
# that needs a @Deployment for the API to go live.
##############################################################################

# Rest API
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = var.app_name
  description = "An api on top of AWS Lambda."
}

# Proxy Resource
resource "aws_api_gateway_resource" "resource_proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "{proxy+}"
}

# Root Methods/Integrations :: Client towards Lambda
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
}

# Root Method/Integrtation Responses :: Lambda towards Client
resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
   rest_api_id = aws_api_gateway_rest_api.rest_api.id
   resource_id = aws_api_gateway_rest_api.rest_api.root_resource_id
   http_method = aws_api_gateway_method.method.http_method
   status_code = aws_api_gateway_method_response.method_response.status_code

   response_templates = {
       "application/json" = ""
   }

  depends_on = [
    aws_api_gateway_integration.integration
  ]
}

# Proxy Methods/Integrations :: Client towards Lambda
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.resource_proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.resource_proxy.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
  cache_key_parameters    = [
    "method.request.path.proxy"
  ]
}

# Proxy Method/Integrtation Responses :: Lambda towards Client
resource "aws_api_gateway_method_response" "proxy_method_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.resource_proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "proxy_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.resource_proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method
  status_code = aws_api_gateway_method_response.proxy_method_response.status_code

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.proxy_integration
  ]
}

# Stage
resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = var.stage_name
  deployment_id = aws_api_gateway_deployment.deployment.id
  description   = "AWS Lambda api on ECR container image"
}

# Deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  triggers    = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.rest_api.body))
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_api_gateway_integration.integration,
    aws_api_gateway_integration.proxy_integration,
  ]
}

# Allow API Gateway to invoke the Lambda
resource "aws_lambda_permission" "gateway_invoke_lambda" {
  statement_id  = "APIGatewayInvoke${var.app_name}Lambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*/*"
}

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
}

######################################
# Creates the function
######################################

# Function itself
resource "aws_lambda_function" "fake_data" {
  function_name = "fake-data-api"
  package_type  = "Image"
  image_uri     = "${var.account_id}.dkr.ecr.us-east-1.amazonaws.com/r0m4n.com/fake-data-api:0.0.12"
  role          = aws_iam_role.lambda_role.arn
}

# IAM
resource "aws_iam_role" "lambda_role" {
  name = "fake-data-api-role"
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
# There are a TON of pieces to this
# just to set up a proxy between
# lambda and API Gateway.
# The hierarchy is like this:
#
# @API
# |- @Root Method -> @Root Integration -> {Lambda}
# |  @Root Method Response <- @Root Integration Response <- {Lambda}
# `- @Proxy Resource
#    `- @Proxy Method -> @Proxy Integration -> {Lambda}
#       @Proxy Method Response <- @Proxy Integration Response <- {Lambda}
#
# Then finally the IAM to allow API Gateway to invoke the Lambda
##############################################################################

# Rest API
resource "aws_api_gateway_rest_api" "fake_data" {
  name        = "fake-data-api"
  description = "A fake data api on lambda."
}

# Proxy Resource
resource "aws_api_gateway_resource" "fake_data_proxy" {
  rest_api_id = aws_api_gateway_rest_api.fake_data.id
  parent_id   = aws_api_gateway_rest_api.fake_data.root_resource_id
  path_part   = "{proxy+}"
}

# Root Methods/Integrations :: Client towards Lambda
resource "aws_api_gateway_method" "fake_data" {
  rest_api_id   = aws_api_gateway_rest_api.fake_data.id
  resource_id   = aws_api_gateway_rest_api.fake_data.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "fake_data" {
  rest_api_id             = aws_api_gateway_rest_api.fake_data.id
  resource_id             = aws_api_gateway_rest_api.fake_data.root_resource_id
  http_method             = aws_api_gateway_method.fake_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.fake_data.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
}

# Root Method/Integrtation Responses :: Lambda towards Client
resource "aws_api_gateway_method_response" "fake_data" {
  rest_api_id = aws_api_gateway_rest_api.fake_data.id
  resource_id = aws_api_gateway_rest_api.fake_data.root_resource_id
  http_method = aws_api_gateway_method.fake_data.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "fake_data" {
   rest_api_id = aws_api_gateway_rest_api.fake_data.id
   resource_id = aws_api_gateway_rest_api.fake_data.root_resource_id
   http_method = aws_api_gateway_method.fake_data.http_method
   status_code = aws_api_gateway_method_response.fake_data.status_code

   response_templates = {
       "application/json" = ""
   }

  depends_on = [
    aws_api_gateway_integration.fake_data
  ]
}

# Proxy Methods/Integrations :: Client towards Lambda
resource "aws_api_gateway_method" "fake_data_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.fake_data.id
  resource_id   = aws_api_gateway_resource.fake_data_proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "fake_data_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.fake_data.id
  resource_id             = aws_api_gateway_resource.fake_data_proxy.id
  http_method             = aws_api_gateway_method.fake_data_proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.fake_data.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
  cache_key_parameters    = [
    "method.request.path.proxy"
  ]
}

# Proxy Method/Integrtation Responses :: Lambda towards Client
resource "aws_api_gateway_method_response" "fake_data_proxy" {
  rest_api_id = aws_api_gateway_rest_api.fake_data.id
  resource_id = aws_api_gateway_resource.fake_data_proxy.id
  http_method = aws_api_gateway_method.fake_data_proxy.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "fake_data_proxy" {
  rest_api_id = aws_api_gateway_rest_api.fake_data.id
  resource_id = aws_api_gateway_resource.fake_data_proxy.id
  http_method = aws_api_gateway_method.fake_data_proxy.http_method
  status_code = aws_api_gateway_method_response.fake_data_proxy.status_code

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.fake_data_proxy
  ]
}

# Stage
resource "aws_api_gateway_stage" "fake_data" {
  rest_api_id   = aws_api_gateway_rest_api.fake_data.id
  stage_name    = "v0"
  deployment_id = aws_api_gateway_deployment.fake_data.id
  description   = "lambda api on container image"
}

# Deployment
resource "aws_api_gateway_deployment" "fake_data" {
  rest_api_id = aws_api_gateway_rest_api.fake_data.id
  triggers    = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.fake_data.body))
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_api_gateway_integration.fake_data,
    aws_api_gateway_integration.fake_data_proxy,
  ]
}

# Allow API Gateway to invoke the Lambda
resource "aws_lambda_permission" "gateway_invoke_lambda" {
  statement_id  = "APIGatewayInvokeFakeDataLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fake_data.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.fake_data.execution_arn}/*/*/*"
}

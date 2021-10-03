output api_endpoint {
  value       = aws_api_gateway_stage.stage.invoke_url
  description = "The acutal live API endpoint that you will use to hit the API with."
}

provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config {
    bucket = "tto-terra-state-up-and-running"
    key = "tto-serverless/terraform.tfstate"
    region = "us-east-1"
  }
}

terraform {
  backend "s3" {
    bucket = "tto-terra-state-up-and-running"
    key = "tto-serverless/user-profile/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "tto-terra-state-up-and-running-lock-table"
  }
}

resource "aws_lambda_function" "func" {
  filename = "func.zip"
  function_name = "user-profile"
  source_code_hash = "${base64sha256(file("func.zip"))}"
  runtime = "nodejs6.10"
  handler = "index.handler"
  role = "${data.terraform_remote_state.infra.api-gateway-lambda-exec-role-arn}"
  environment  {
    variables = {
      DOMAIN = "c63.auth0.com"
      AUTH0_SECRET = "f7Cl3MRjnVMg6hDGA5W-ruxpo9uscZqGQdMFPgfckRCwqzbyCDg3OkqKAWMMgzLA"
    }
  }
}

resource "aws_api_gateway_method" "MyDemoServerlessUserProfileMethod" {
  rest_api_id = "${data.terraform_remote_state.infra.demo-serverless-rest-api-id}"
  resource_id = "${data.terraform_remote_state.infra.demo-serverless-user-profile-id}"
  http_method = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.func.arn}"
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-east-1:124434922299:${data.terraform_remote_state.infra.demo-serverless-rest-api-id}/*/${aws_api_gateway_method.MyDemoServerlessUserProfileMethod.http_method}/user-profile"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = "${data.terraform_remote_state.infra.demo-serverless-rest-api-id}"
  resource_id = "${data.terraform_remote_state.infra.demo-serverless-user-profile-id}"
  http_method = "${aws_api_gateway_method.MyDemoServerlessUserProfileMethod.http_method}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.func.arn}/invocations"

  request_templates {
    "application/json" = <<-EOF
    {
      "authToken": "$input.params('Authorization')"
    }
    EOF
  }

  passthrough_behavior = "WHEN_NO_TEMPLATES"
}

resource "aws_api_gateway_deployment" "MyUserProfileDeployment" {
  depends_on = ["aws_api_gateway_integration.integration"]
  rest_api_id = "${data.terraform_remote_state.infra.demo-serverless-rest-api-id}"
  stage_name = "test"
  description = "Fix CORS problems 2"
}


resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${data.terraform_remote_state.infra.demo-serverless-rest-api-id}"
  resource_id = "${data.terraform_remote_state.infra.demo-serverless-user-profile-id}"
  http_method = "${aws_api_gateway_method.MyDemoServerlessUserProfileMethod.http_method}"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = "${data.terraform_remote_state.infra.demo-serverless-rest-api-id}"
  resource_id = "${data.terraform_remote_state.infra.demo-serverless-user-profile-id}"
  http_method = "${aws_api_gateway_method.MyDemoServerlessUserProfileMethod.http_method}"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTION'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

output "invoke_url" {
  value = "${aws_api_gateway_deployment.MyUserProfileDeployment.invoke_url}"
}

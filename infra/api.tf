resource "aws_api_gateway_rest_api" "MyDemoServerlessAPI" {
  name = "MyDemoServerlessAPI"
  description = "This is demo serverless api"
}

resource "aws_api_gateway_resource" "MyDemoServerlessUserProfileResource"{
  rest_api_id = "${aws_api_gateway_rest_api.MyDemoServerlessAPI.id}"
  parent_id = "${aws_api_gateway_rest_api.MyDemoServerlessAPI.root_resource_id}"
  path_part = "user-profile"
}

output "demo-serverless-rest-api-id" {
  value = "${aws_api_gateway_rest_api.MyDemoServerlessAPI.id}"
}

output "demo-serverless-user-profile-id" {
  value = "${aws_api_gateway_resource.MyDemoServerlessUserProfileResource.id}"
}

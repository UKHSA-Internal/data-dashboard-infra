resource "aws_cloudfront_key_value_store" "password_protection" {
  count = local.add_password_protection ? 1 : 0
  name  = "${local.prefix}-password-protection"
}

resource "aws_cloudfront_function" "password_protection" {
  count                        = local.add_password_protection ? 1 : 0
  name                         = "${local.prefix}-password-protection"
  runtime                      = "cloudfront-js-2.0"
  publish                      = true
  key_value_store_associations = [
    aws_cloudfront_key_value_store.password_protection[0].arn
  ]
  code = <<-EOF
  const cf = require('cloudfront')

  async function getCredentials(KvStoreId) {
      const kvsHandle = cf.kvs(KvStoreId);
      const username = await kvsHandle.get("username");
      const password = await kvsHandle.get("password");
      return {
          username: username,
          password: password,
      }
  }

  function extractFinalSection(inputString) {
      const parts = inputString.split('/');
      return parts[parts.length - 1];
  }

  function buildEncodedString(credentials) {
      const encodedCredentials = btoa(`$${credentials.username}:$${credentials.password}`);
      return `Basic $${encodedCredentials}`
  }

  async function handler(event) {
      const authorizationHeaders = event.request.headers.authorization;
      const kvStoreArn = "${aws_cloudfront_key_value_store.password_protection[0].arn}"
      const KvStoreId = extractFinalSection(kvStoreArn)

      const credentials = await getCredentials(KvStoreId)
      const encodedString = buildEncodedString(credentials)

      if (authorizationHeaders && authorizationHeaders.value === encodedString) {
          return event.request;
      }

      return {
          statusCode: 401,
          statusDescription: "Unauthorized",
          headers: {
              "www-authenticate": {value: 'Basic'},
          },
      };
  }

  handler;
  EOF
}

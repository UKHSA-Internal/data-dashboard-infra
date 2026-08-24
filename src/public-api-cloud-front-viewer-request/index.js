function handler(event) {
  const request = event.request;

  const acceptHeader = request.headers.accept
    ? request.headers.accept.value
    : "";

  const normalizedAcceptHeader = normalizeAcceptHeader(acceptHeader);
  const transformedAcceptHeader = getAcceptHeaderForRequestedJSONFormat(normalizedAcceptHeader, request)

  const message = `uri: "${request.uri}" accept_header: "${acceptHeader}" normalized_accept_header: "${normalizedAcceptHeader}"`;
  console.log(message);

  request.headers["accept"] = { value: transformedAcceptHeader };

  // Duplicate of logic in cloudfront-cache-bypass
  // Bypassing the cache for authenticated requests
  const headers = request.headers;
  const cookies = request.cookies;

  let hasAuthSession = false;
  if (cookies) {
    hasAuthSession = Object.keys(cookies).some(function (name) {
        console.log(`Cookie name is: ${name}`)
        return name.includes('authjs.session-token');
    });
  }

  if (hasAuthSession || headers['HTTP_X_UHD_AUTH']) {
      // Append a unique query string so it's treated as an unreachable object by CloudFront
      request.querystring['_cb'] = { value: Date.now().toString() + event.context.requestId };
  }

  return request;
}

function normalizeAcceptHeader(acceptHeader) {
  if (acceptHeader.includes("html")) {
    return "text/html";
  }

  if (acceptHeader.includes("json") || acceptHeader == "") {
    return "application/json";
  }

  return "";
}

function getAcceptHeaderForRequestedJSONFormat(normalizedAcceptHeader, request) {
  // When a query param of `format=json` is provided
  // Then we return "application/json" as the accept header
  // Otherwise return the originally normalized accept header
  const formatQueryParam = request.querystring["format"]
    ? request.querystring["format"].value
    : "";

  if (formatQueryParam === "json") {
    return "application/json";
  }
  return normalizedAcceptHeader;
}

function handler(event) {
  const request = event.request;

  const acceptHeader = request.headers.accept
    ? request.headers.accept.value
    : "";

  const normalizedAcceptHeader = normalizeAcceptHeader(acceptHeader);

  const message = `uri: "${request.uri}" accept_header: "${acceptHeader}" normalized_accept_header: "${normalizedAcceptHeader}"`;
  console.log(message);

  request.headers["accept"] = { value: normalizedAcceptHeader };

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

handler;

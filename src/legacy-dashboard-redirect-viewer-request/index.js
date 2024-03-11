function handler(event) {
  const requestUrl = getRequestUrl(event.request);
  const redirectUrl = getRedirectUrl(event.request);

  console.log(`Redirecting ${requestUrl} to ${redirectUrl}`);

  const response = {
    statusCode: 301,
    statusDescription: "Moved Permanently",
    headers: { location: { value: redirectUrl } },
  };

  return response;
}

function getRedirectUrl(request) {
  const host = request.headers.host.value;
  const hostParts = host.split(".");

  if (hostParts.length == 5) {
    return `https://${hostParts[0]}.ukhsa-dashboard.data.gov.uk`;
  }

  if (hostParts.length == 6) {
    return `https://${hostParts[0]}.${hostParts[1]}.ukhsa-dashboard.data.gov.uk`;
  }

  return "https://ukhsa-dashboard.data.gov.uk";
}

function getRequestUrl(request) {
  const host = request.headers.host.value;
  const uri = request.uri;

  return `${host}${uri}`;
}

handler;

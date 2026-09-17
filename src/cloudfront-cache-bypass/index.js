function handler(event) {
    const request = event.request;
    const headers = request.headers;
    const cookies = request.cookies;

    var hasAuthSession = false;
    if (cookies) {
        hasAuthSession = Object.keys(cookies).some(function (name) {
            return name.includes('authjs.session-token');
        });
    }

    var hasAuthHeader = false;
    if (headers) {
        hasAuthHeader = Object.keys(headers).some(function (name) {
            return name === 'x-uhd-auth' || name === 'x_uhd_auth' || name === 'authorization';
        });
    }

    if (hasAuthSession || hasAuthHeader) {
        // Append a unique query string so it's treated as an unreachable object by CloudFront
        request.querystring['_cb'] = { value: Date.now().toString() + event.context.requestId };
    }

    return request;
}

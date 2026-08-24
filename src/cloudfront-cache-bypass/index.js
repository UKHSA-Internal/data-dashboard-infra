function handler(event) {
    const request = event.request;
    const headers = request.headers;
    const cookies = request.cookies;

    let hasAuthSession = false;
    if (cookies) {
        hasAuthSession = Object.keys(cookies).some(function (name) {
            return name.includes('authjs.session-token');
        });
    }

    if (hasAuthSession || headers['HTTP_X_UHD_AUTH']) {
        // Append a unique query string so it's treated as an unreachable object by CloudFront
        request.querystring['_cb'] = { value: Date.now().toString() + event.context.requestId };
    }

    return request;
}

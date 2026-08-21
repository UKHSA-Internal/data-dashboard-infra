function handler(event) {
    var request = event.request;
    var headers = request.headers;
    var cookies = request.cookies;

    var hasAuthSession = Object.keys(cookies).some(function (name) {
        return name.indexOf('authjs.session-token') !== -1;
    });

    if (hasAuthSession || headers['HTTP_X_UHD_AUTH']) {
        // Append a random, unique, query string so it's treated as an unreachable object by CloudFront
        request.querystring['_cb'] = { value: Date.now().toString() + Math.random().toString(36).slice(2) };
    }

    return request;
}

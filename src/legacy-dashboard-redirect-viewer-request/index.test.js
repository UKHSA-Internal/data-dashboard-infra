import {expect, test} from '@jest/globals';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import vm from 'node:vm';

// import the handler function from the index.js file - we can't use an export in the index.js file because of the
// limited keywords available in the cloudfront function runtime, so we execute it using the vm module in this scope
// and associate it with the original file it came from to ensure jest can associate it correctly for coverage
const filename = resolve('./index.js');
const code = readFileSync(filename, 'utf-8');
// NOSONAR
const { handler } = vm.runInThisContext(`(function() {\n${code}\nreturn { handler };\n})()`, {filename});


test.each([
  {
    host: "491aa455.dev.coronavirus.data.gov.uk",
    redirectTo: "https://491aa455.dev.ukhsa-dashboard.data.gov.uk",
  },
  {
    host: "dev.coronavirus.data.gov.uk",
    redirectTo: "https://dev.ukhsa-dashboard.data.gov.uk",
  },
  {
    host: "test.coronavirus.data.gov.uk",
    redirectTo: "https://test.ukhsa-dashboard.data.gov.uk",
  },
  {
    host: "uat.coronavirus.data.gov.uk",
    redirectTo: "https://uat.ukhsa-dashboard.data.gov.uk",
  },
  {
    host: "coronavirus.data.gov.uk",
    redirectTo: "https://ukhsa-dashboard.data.gov.uk",
  },
  {
    host: "d111111abcdef8.cloudfront.net",
    redirectTo: "https://ukhsa-dashboard.data.gov.uk",
  },
])(
  "Host header '$host' should redirect to '$redirectTo'",
  ({ host, redirectTo }) => {
    const event = {
      version: "1.0",
      request: {
        uri: "/",
        headers: {
          host: { value: host },
        },
      },
    };

    const expected = {
      statusCode: 301,
      statusDescription: "Moved Permanently",
      headers: { location: { value: redirectTo } },
    };

    const result = handler(event);

    expect(result).toEqual(expected);
  }
);

test.each([
  {
    path: "/",
    redirectTo: "https://ukhsa-dashboard.data.gov.uk",
  },
  {
    path: "/details/testing",
    redirectTo: "https://ukhsa-dashboard.data.gov.uk",
  },
  {
    path: "/details/interactive-map/cases",
    redirectTo: "https://ukhsa-dashboard.data.gov.uk",
  },
  {
    path: "/foo/bar",
    redirectTo: "https://ukhsa-dashboard.data.gov.uk",
  },
])("Path '$path' should redirect to '$redirectTo'", ({ path, redirectTo }) => {
  const event = {
    version: "1.0",
    request: {
      uri: path,
      headers: {
        host: { value: "coronavirus.data.gov.uk" },
      },
    },
  };

  const expected = {
    statusCode: 301,
    statusDescription: "Moved Permanently",
    headers: { location: { value: redirectTo } },
  };

  const result = handler(event);

  expect(result).toEqual(expected);
});

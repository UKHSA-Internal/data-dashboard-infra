const originRequest = require("./index");
const handler = originRequest.__get__("handler");

test("Headers should not be removed", () => {
  const event = {
    request: {
      uri: "https://foo.bar/baz",
      querystring: {},
      headers: {
        accept: { value: "text/html" },
        "x-bar": { value: "baz" },
        "x-foo": { value: "bar" },
      },
    },
  };

  const expected = {
    accept: { value: "text/html" },
    "x-bar": { value: "baz" },
    "x-foo": { value: "bar" },
  };

  const result = handler(event).headers;

  expect(result).toEqual(expected);
});

test.each([
  { accept: "text/html, foo/bar", expected: "text/html" },
  { accept: "application/json, foo/bar", expected: "application/json" },
  {
    accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    expected: "text/html",
  },
  {
    accept: "application/json,text/*;q=0.99",
    expected: "application/json",
  },
  {
    accept: "",
    expected: "application/json",
  },
])(
  "Accept header '$accept' should normalized to '$expected'",
  ({ accept, expected }) => {
    const event = {
      request: {
        querystring: {},
        headers: {
          accept: { value: accept },
        },
      },
    };

    const result = handler(event);

    expect(result.headers.accept.value).toEqual(expected);
  }
);

test.each([
  "image/webp,image/avif,image/jxl,image/heic,image/heic-sequence,video/*;q=0.8,image/png,image/svg+xml,image/*;q=0.8,*/*;q=0.5",
  "text/css,*/*;q=0.1",
  "*/*",
])(
  "Accept headers for images, css etc should be normalized to '' - test for '%s'",
  (accept) => {
    const event = {
      request: {
        querystring: {},
        headers: {
          accept: { value: accept },
        },
      },
    };

    const result = handler(event);

    expect(result.headers.accept.value).toEqual("");
  }
);

test("When accept header is missing it defaults to application/json", () => {
  const event = {
    request: {
      querystring: {},
      headers: {
        "x-bar": { value: "baz" },
        "x-foo": { value: "bar" },
      },
    },
  };

  const result = handler(event);

  expect(result.headers.accept.value).toEqual("application/json");
});

test("When format=json query param is provided it defaults to application/json", () => {
  const event = {
    request: {
      querystring: {"format": {value: "json"}},
      headers: {
        accept: { value: "text/plain" },
      },
    },
  };

  const result = handler(event);

  expect(result.headers.accept.value).toEqual("application/json");
});

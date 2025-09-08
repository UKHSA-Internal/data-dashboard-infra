process.env.SECRET_COGNITO_CREDENTIALS = "cognito-service-credentials";
process.env.UKHSA_TENANT_ID = "ukhsa-tenant-id";
process.env.COGNITO_USER_POOL_ID = "fake-user-pool-id";
process.env.UKHSA_CLIENT_ID = "azure-client-id";
process.env.UKHSA_CLIENT_SECRET = "azure-client-secret";

const { handler } = require("./index.js");
const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");

// Mocks AWS SecretsManager
jest.mock("@aws-sdk/client-secrets-manager", () => {
  const actual = jest.requireActual("@aws-sdk/client-secrets-manager");
  return {
    SecretsManagerClient: jest.fn(() => ({
      send: jest.fn((command) => {
        if (command.input.SecretId === "cognito-service-credentials") {
          return Promise.resolve({
            SecretString: JSON.stringify({
              client_id: "fake-client-id",
              client_secret: "fake-client-secret"
            })
          });
        }
        return Promise.reject(new Error("Unknown secret"));
      })
    })),
    GetSecretValueCommand: actual.GetSecretValueCommand
  };
});

// Mocks JWKS
jest.mock("jwks-rsa", () => () => ({
  getSigningKey: jest.fn((kid, callback) => callback(null, { publicKey: "fake-public-key" })),
}));

// Mock JWT verification
jest.mock("jsonwebtoken", () => ({
  verify: jest.fn((token, key, options, callback) => {
    if (token === "VALID_WITH_GROUP") {
      callback(null, {
        sub: "user-id",
        "custom:groups": JSON.stringify([
          "ab55e906-8ca2-4b93-9d34-5588870688e4"
        ])
      });
    } else if (token === "VALID_WITHOUT_GROUP") {
      callback(null, {
        sub: "user-id",
        "custom:groups": JSON.stringify(["some-other-group-id"])
      });
    } else {
      callback(new Error("jwt malformed"), null);
    }
  })
}));

describe("API Gateway Lambda Authorizer", () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  it("should allow requests with valid JWT including required group", async () => {
    const event = {
      headers: { Authorization: "Bearer VALID_WITH_GROUP" },
      methodArn: "arn:aws:execute-api:example"
    };

    const result = await handler(event);
    expect(result.policyDocument.Statement[0].Effect).toBe("Allow");
    expect(result.context["X-Group-ID"]).toBe("ab55e906-8ca2-4b93-9d34-5588870688e4");
  });

  it("should deny requests without a token", async () => {
    const result = await handler({ headers: {} });
    expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
    expect(result.context.errorMessage).toBe("Missing Authorization header");
  });

  it("should deny requests with an invalid JWT", async () => {
    const event = { headers: { Authorization: "Bearer INVALID_JWT" } };
    const result = await handler(event);
    expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
    expect(result.context.errorMessage).toBe("jwt malformed");
  });

  it("should deny request when REQUIRED_GROUP_ID is missing", async () => {
    const event = {
      headers: { Authorization: "Bearer VALID_WITHOUT_GROUP" },
      methodArn: "arn:aws:execute-api:example"
    };
    const result = await handler(event);
    expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
    expect(result.context.errorMessage).toBe("User not in required group");
  });

  it("should deny request if custom:groups is malformed", async () => {
    jwt.verify.mockImplementationOnce((token, key, options, callback) => {
      callback(null, {
        sub: "user-id",
        "custom:groups": "[not valid JSON"
      });
    });
    const event = {
      headers: { Authorization: "Bearer MALFORMED_GROUPS" },
      methodArn: "arn:aws:execute-api:example"
    };
    const result = await handler(event);
    expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
    expect(result.context.errorMessage).toMatch(/Unexpected token/);
  });

  it("should deny request if custom:groups is missing", async () => {
    jwt.verify.mockImplementationOnce((token, key, options, callback) => {
      callback(null, { sub: "user-id" });
    });
    const event = {
      headers: { Authorization: "Bearer NO_GROUPS" },
      methodArn: "arn:aws:execute-api:example"
    };
    const result = await handler(event);
    expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
    expect(result.context.errorMessage).toBe("User not in required group");
  });
});
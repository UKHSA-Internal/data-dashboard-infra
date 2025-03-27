process.env.SECRET_NAME = "cognito-service-credentials";

const { handler } = require("./index.js");
const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");

// Mock AWS Secrets Manager
jest.mock("@aws-sdk/client-secrets-manager", () => {
  const actualAWS = jest.requireActual("@aws-sdk/client-secrets-manager");
  return {
    SecretsManagerClient: jest.fn(() => ({
      send: jest.fn(() => Promise.resolve({
        SecretString: JSON.stringify({
          client_id: "fake-client-id",
          user_pool_id: "eu-west-2_fakePoolId",
          region: "eu-west-2"
        })
      })),
    })),
    GetSecretValueCommand: actualAWS.GetSecretValueCommand,
  };
});

// Mock JWKS Client
jest.mock("jwks-rsa", () => {
  return jest.fn(() => ({
    getSigningKey: jest.fn((kid, callback) => callback(null, { publicKey: "fake-public-key" })),
  }));
});

// Mock JWT Verification
jest.mock("jsonwebtoken", () => ({
  verify: jest.fn((token, key, options, callback) => {
    if (token === "VALID_COGNITO_JWT") {
      callback(null, {
        sub: "fake-user-id",
        "custom:groups": "[\"group-id-123\",\"group-id-456\"]"
      }); // Simulated decoded JWT
    } else if (token === "VALID_JWT_NO_GROUPS") {
      callback(null, {
        sub: "fake-user-id",
        "custom:groups": "[]"
      });
    } else {
      callback(new Error("jwt malformed"), null);
    }
  }),
}));

describe("Updated API Gateway Cognito Lambda Authorizer", () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  it("allows requests with a valid Cognito JWT containing groups", async () => {
    const event = {
      headers: {
        Authorization: "Bearer VALID_COGNITO_JWT",
      },
      methodArn: "arn:aws:execute-api:region:account-id:api-id/stage/GET/resource"
    };

    const result = await handler(event);

    expect(result.policyDocument.Statement[0].Effect).toBe("Allow");
    expect(result.context["X-Group-ID"]).toBe("group-id-123");
  });

  it("allows requests with a valid JWT but no groups, defaulting to 'unknown'", async () => {
    const event = {
      headers: {
        Authorization: "Bearer VALID_JWT_NO_GROUPS",
      },
      methodArn: "arn:aws:execute-api:region:account-id:api-id/stage/GET/resource"
    };

    const result = await handler(event);

    expect(result.policyDocument.Statement[0].Effect).toBe("Allow");
    expect(result.context["X-Group-ID"]).toBe("unknown");
  });

  it("denies requests without an Authorization token", async () => {
    const event = { headers: {}, methodArn: "arn:aws:execute-api:region:account-id:api-id/stage/GET/resource" };

    const result = await handler(event);

    expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
    expect(result.context.errorMessage).toBe("Missing Authorization header");
  });

  it("denies requests with an invalid JWT", async () => {
    const event = {
      headers: {
        Authorization: "Bearer INVALID_JWT",
      },
      methodArn: "arn:aws:execute-api:region:account-id:api-id/stage/GET/resource"
    };

    const result = await handler(event);

    expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
    expect(result.context.errorMessage).toBe("jwt malformed");
  });
});
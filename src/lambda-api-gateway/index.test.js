process.env.SECRET_NAME = "cognito-service-credentials";
process.env.TENANT_SECRET_NAME = "ukhsa-tenant-id";

const { handler } = require("./index.js");
const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");
const sinon = require("sinon");

// Mock AWS Secrets Manager
jest.mock("@aws-sdk/client-secrets-manager", () => {
  const actualAWS = jest.requireActual("@aws-sdk/client-secrets-manager");
  return {
    SecretsManagerClient: jest.fn(() => ({
      send: jest.fn((command) => {
        // Check the secret ID requested
        if (command.input && command.input.SecretId) {
          if (command.input.SecretId.includes("cognito-service-credentials")) {
            // Return credentials
            return Promise.resolve({
              SecretString: JSON.stringify({
                client_id: "fake-client-id",
                client_secret: "fake-client-secret"
              })
            });
          } else if (command.input.SecretId.includes("tenant-id")) {
            // Return tenant id
            return Promise.resolve({
              SecretString: JSON.stringify({
                tenant_id: "fake-tenant-id"
              })
            });
          }
        }
        return Promise.reject(new Error("Unknown command"));
      }),
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
        if (token === "VALID_TEST_JWT") {
            callback(null, { sub: "fake-user-id" }); // Simulated decoded JWT
        } else {
            callback(new Error("jwt malformed"), null);
        }
    }),
}));

describe("API Gateway Lambda Authorizer", () => {
    let sandbox;

    beforeEach(() => {
        sandbox = sinon.createSandbox();
    });

    afterEach(() => {
        sandbox.restore();
        jest.clearAllMocks();
    });

    it("should allow requests with a valid JWT", async () => {
        const event = {
            headers: {
                Authorization: "Bearer VALID_TEST_JWT",
            },
        };

        const result = await handler(event);

        expect(result.policyDocument.Statement[0].Effect).toBe("Allow");
    });

    it("should deny requests without a token", async () => {
        const event = { headers: {} };

        const result = await handler(event);

        expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
        expect(result.context.errorMessage).toBe("Missing Authorization header");
    });

    it("should deny requests with an invalid JWT", async () => {
        const event = {
            headers: {
                Authorization: "Bearer INVALID_JWT",
            },
        };

        const result = await handler(event);

        expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
        expect(result.context.errorMessage).toBe("jwt malformed");
    });
});
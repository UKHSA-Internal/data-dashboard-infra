const lambdaHandler = require("./index");
const sinon = require("sinon");

describe("API Gateway Lambda Authorizer", () => {
    let getSecretsStub, getTenantIdStub, jwtVerifyStub;

    beforeEach(() => {
        // Stub dependencies
        getSecretsStub = sinon.stub(require("./index"), "getSecrets").resolves({
            client_id: "fake-client-id",
            client_secret: "fake-client-secret"
        });

        getTenantIdStub = sinon.stub(require("./index"), "getTenantId").resolves("fake-tenant-id");

        jwtVerifyStub = sinon.stub(require("jsonwebtoken"), "verify").callsFake((token, key, options, callback) => {
            if (token === "VALID_TEST_JWT") {
                callback(null, { sub: "user-123", groups: ["test-group-id"] });
            } else {
                callback(new Error("Invalid token"), null);
            }
        });
    });

    afterEach(() => {
        // Restore original functions
        sinon.restore();
    });

    /**
     * Given a valid JWT token
     * When the Lambda function is invoked
     * Then it should return an "Allow" policy with the extracted group ID
     */
    test("Allows requests with a valid JWT", async () => {
        const event = {
            headers: { Authorization: "Bearer VALID_TEST_JWT" },
            methodArn: "arn:aws:execute-api:region:account-id:api-id/stage/method/resource"
        };

        const result = await lambdaHandler.handler(event);

        expect(result.policyDocument.Statement[0].Effect).toBe("Allow");
        expect(result.context["X-Group-ID"]).toBe("test-group-id");
    });

    /**
     * Given an invalid JWT token
     * When the Lambda function is invoked
     * Then it should return a "Deny" policy
     */
    test("Denies requests with an invalid JWT", async () => {
        const event = {
            headers: { Authorization: "Bearer INVALID_TEST_JWT" },
            methodArn: "arn:aws:execute-api:region:account-id:api-id/stage/method/resource"
        };

        const result = await lambdaHandler.handler(event);

        expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
        expect(result.context.errorMessage).toBe("Invalid token");
    });

    /**
     * Given no Authorization header
     * When the Lambda function is invoked
     * Then it should return a "Deny" policy with an error message
     */
    test("Denies requests without a token", async () => {
        const event = { headers: {}, methodArn: "arn:aws:execute-api:region:account-id:api-id/stage/method/resource" };

        const result = await lambdaHandler.handler(event);

        expect(result.policyDocument.Statement[0].Effect).toBe("Deny");
        expect(result.context.errorMessage).toBe("No token provided");
    });
});
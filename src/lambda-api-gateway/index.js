const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");
const util = require("util");

const secretsClient = new SecretsManagerClient({});
let cachedSecrets = null;

async function getSecrets() {
    // This caching only lasts as long as the Lambda instance is warm.
    // If the function experiences a cold start, cachedSecrets will be reset.
    if (cachedSecrets) return cachedSecrets;

    try {
        const command = new GetSecretValueCommand({ SecretId: "ukhsa_oidc_credentials" });
        const commandTenant = new GetSecretValueCommand({ SecretId: "ukhsa-tenant-id" });

        // Fetch both secrets in parallel for efficiency
        const [oidcResponse, tenantResponse] = await Promise.all([
            secretsClient.send(command),
            secretsClient.send(commandTenant)
        ]);

        cachedSecrets = {
            oidc: JSON.parse(oidcResponse.SecretString),
            tenantId: JSON.parse(tenantResponse.SecretString).tenant_id
        };

        return cachedSecrets;
    } catch (error) {
        console.error("Failed to retrieve secrets:", error);
        throw new Error("Secrets retrieval failed");
    }
}

exports.handler = async (event) => {
    try {
        const secrets = await getSecrets();
        const UKHSA_JWKS_URL = `https://login.microsoftonline.com/${secrets.tenantId}/discovery/v2.0/keys`;

        const client = jwksClient({ jwksUri: UKHSA_JWKS_URL });
        const getSigningKey = util.promisify(client.getSigningKey.bind(client));

        // Extract JWT from request headers
        const token = event.headers?.Authorization?.replace("Bearer ", "") || event.headers?.authorization?.replace("Bearer ", "");
        if (!token) throw new Error("Missing Authorization header");

        const decoded = await new Promise((resolve, reject) => {
            jwt.verify(token, async (header, callback) => {
                try {
                    const key = await getSigningKey(header.kid);
                    callback(null, key.publicKey || key.rsaPublicKey);
                } catch (error) {
                    callback(error);
                }
            }, { algorithms: ["RS256"] }, (err, decoded) => {
                if (err) reject(err);
                else resolve(decoded);
            });
        });

        const groupId = decoded["groups"]?.[0] || "unknown";

        return {
            principalId: decoded.sub || "user",
            policyDocument: {
                Version: "2012-10-17",
                Statement: [{ Action: "execute-api:Invoke", Effect: "Allow", Resource: event.methodArn }]
            },
            context: { "X-Group-ID": groupId }
        };

    } catch (error) {
        console.error("Token verification failed:", error.message);
        return {
            principalId: "user",
            policyDocument: {
                Version: "2012-10-17",
                Statement: [{ Action: "execute-api:Invoke", Effect: "Deny", Resource: event.methodArn }]
            },
            context: { "errorMessage": error.message }
        };
    }
};
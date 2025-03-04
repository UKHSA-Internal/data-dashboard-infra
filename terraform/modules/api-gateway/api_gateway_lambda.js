const AWS = require('aws-sdk');
const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");

const secretsManager = new AWS.SecretsManager();
let cachedSecrets = null;

async function getSecrets() {
    if (cachedSecrets) return cachedSecrets;

    const secretData = await secretsManager.getSecretValue({ SecretId: "ukhsa_oidc_credentials" }).promise();
    cachedSecrets = JSON.parse(secretData.SecretString);
    return cachedSecrets;
}

async function getTenantId() {
    const secretData = await secretsManager.getSecretValue({ SecretId: "ukhsa-tenant-id" }).promise();
    return JSON.parse(secretData.SecretString).tenant_id;
}

exports.handler = async (event) => {
    const secrets = await getSecrets();
    const TENANT_ID = await getTenantId();
    const UKHSA_JWKS_URL = "https://login.microsoftonline.com/${TENANT_ID}/discovery/v2.0/keys";

    const client = jwksClient({ jwksUri: UKHSA_JWKS_URL });

    async function getSigningKey(header) {
        return new Promise((resolve, reject) => {
            client.getSigningKey(header.kid, (err, key) => {
                if (err) return reject(err);
                resolve(key.publicKey || key.rsaPublicKey);
            });
        });
    }

    try {
        const token = event.headers?.Authorization?.replace("Bearer ", "") || event.headers?.authorization?.replace("Bearer ", "");
        if (!token) throw new Error("No token provided");

        const decoded = await new Promise((resolve, reject) => {
            jwt.verify(token, getSigningKey, { algorithms: ["RS256"] }, (err, decoded) => {
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
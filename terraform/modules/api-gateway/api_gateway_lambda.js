const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");

const TENANT_ID = process.env.UKHSA_TENANT_ID;
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

exports.handler = async (event) => {
    console.log(`Using Tenant ID: ${TENANT_ID}`);

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

        console.log(`Token verified successfully for Group ID: ${groupId}`);

        return {
            principalId: decoded.sub || "user",
            policyDocument: {
                Version: "2012-10-17",
                Statement: [
                    {
                        Action: "execute-api:Invoke",
                        Effect: "Allow",
                        Resource: event.methodArn
                    }
                ]
            },
            context: { "X-Group-ID": groupId }
        };

    } catch (error) {
        console.error("Token verification failed:", error.message);

        return {
            principalId: "user",
            policyDocument: {
                Version: "2012-10-17",
                Statement: [
                    {
                        Action: "execute-api:Invoke",
                        Effect: "Deny",
                        Resource: event.methodArn
                    }
                ]
            },
            context: { "errorMessage": error.message }
        };
    }
};
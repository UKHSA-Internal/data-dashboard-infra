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
    const credentialsSecretName = process.env.SECRET_NAME;

    const credentialsResponse = await secretsClient.send(
      new GetSecretValueCommand({ SecretId: credentialsSecretName })
    );

    const credentialsParsed = JSON.parse(credentialsResponse.SecretString);

    cachedSecrets = {
      clientId: credentialsParsed.client_id,
      userPoolId: credentialsParsed.user_pool_id,
      region: credentialsParsed.region
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

    const COGNITO_JWKS_URL = `https://cognito-idp.${secrets.region}.amazonaws.com/${secrets.userPoolId}/.well-known/jwks.json`;

    const client = jwksClient({ jwksUri: COGNITO_JWKS_URL });
    const getSigningKey = util.promisify(client.getSigningKey.bind(client));

    // Extract JWT from headers
    const token = event.headers?.Authorization?.replace("Bearer ", "") ||
                  event.headers?.authorization?.replace("Bearer ", "");
    if (!token) throw new Error("Missing Authorization header");

    // Verify the token explicitly using Cognito JWKS
    const decoded = await new Promise((resolve, reject) => {
      jwt.verify(
        token,
        async (header, callback) => {
          try {
            const key = await getSigningKey(header.kid);
            callback(null, key.publicKey || key.rsaPublicKey);
          } catch (err) {
            callback(err);
          }
        },
        { algorithms: ["RS256"] },
        (err, decodedToken) => {
          if (err) reject(err);
          else resolve(decodedToken);
        }
      );
    });

    // Explicitly parse custom:groups (JSON-encoded string)
    const customGroupsRaw = decoded["custom:groups"] || "[]";
    const customGroups = JSON.parse(customGroupsRaw);

    const groupId = customGroups[0] || "unknown";

    return {
      principalId: decoded.sub || "user",
      policyDocument: {
        Version: "2012-10-17",
        Statement: [
          { Action: "execute-api:Invoke", Effect: "Allow", Resource: event.methodArn }
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
          { Action: "execute-api:Invoke", Effect: "Deny", Resource: event.methodArn }
        ]
      },
      context: { "errorMessage": error.message }
    };
  }
};
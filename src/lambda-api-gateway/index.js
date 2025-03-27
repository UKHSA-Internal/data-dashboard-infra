const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");
const util = require("util");

const REQUIRED_GROUP_ID = "ab55e906-8ca2-4b93-9d34-5588870688e4";

const secretsClient = new SecretsManagerClient({});
let cachedSecrets = null;

async function getSecrets() {
  if (cachedSecrets) return cachedSecrets;

  try {
    const cognitoCredentials = process.env.SECRET_COGNITO_CREDENTIALS;
    const ukhsaTenantId = process.env.UKHSA_TENANT_ID;

    const credentialsResponse = await secretsClient.send(
      new GetSecretValueCommand({ SecretId: cognitoCredentials })
    );
    const credentialsParsed = JSON.parse(credentialsResponse.SecretString);

    cachedSecrets = {
      clientId: credentialsParsed.client_id,
      clientSecret: credentialsParsed.client_secret,
      tenantId: ukhsaTenantId
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

    const token = event.headers?.Authorization?.replace("Bearer ", "") ||
                  event.headers?.authorization?.replace("Bearer ", "");
    if (!token) throw new Error("Missing Authorization header");

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

    const userGroups = decoded["groups"] || [];
    const userCustomGroups = decoded["custom:groups"] ? JSON.parse(decoded["custom:groups"]) : [];

    const allGroups = [...userGroups, ...userCustomGroups];

    if (!allGroups.includes(REQUIRED_GROUP_ID)) {
      throw new Error("User not in required group");
    }

    return {
      principalId: decoded.sub || "user",
      policyDocument: {
        Version: "2012-10-17",
        Statement: [
          { Action: "execute-api:Invoke", Effect: "Allow", Resource: event.methodArn }
        ]
      },
      context: { "X-Group-ID": REQUIRED_GROUP_ID }
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
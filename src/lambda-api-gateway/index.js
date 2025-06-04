const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");
const util = require("util");

// hardcode the group id for now, group name for this id is App.Auth.Atlassian.agreed
const REQUIRED_GROUP_ID = "ab55e906-8ca2-4b93-9d34-5588870688e4";

const secretsClient = new SecretsManagerClient({});
let cachedSecrets = null;

async function getSecrets() {
  if (cachedSecrets) return cachedSecrets;

  const credentials = await secretsClient.send(
    new GetSecretValueCommand({ SecretId: process.env.SECRET_COGNITO_CREDENTIALS })
  );

  const { client_id, client_secret } = JSON.parse(credentials.SecretString);

  cachedSecrets = {
    clientId: client_id,
    clientSecret: client_secret,
    tenantId: process.env.UKHSA_TENANT_ID
  };

  return cachedSecrets;
}

exports.handler = async (event) => {
  try {
    const secrets = await getSecrets();
    const jwksUri = `https://cognito-idp.eu-west-2.amazonaws.com/${process.env.COGNITO_USER_POOL_ID}/.well-known/jwks.json`;

    const client = jwksClient({ jwksUri });
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

    const userGroups = decoded["custom:groups"] ? JSON.parse(decoded["custom:groups"]) : [];
    if (!userGroups.includes(REQUIRED_GROUP_ID)) {
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
      context: {
        "X-Group-ID": REQUIRED_GROUP_ID
      }
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
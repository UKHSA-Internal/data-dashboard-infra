// index.js
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");
const util = require("util");
const https = require("https");
const querystring = require("querystring");

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
    tenantId: process.env.UKHSA_TENANT_ID,
    azureClientId: process.env.UKHSA_CLIENT_ID,
    azureClientSecret: process.env.UKHSA_CLIENT_SECRET
  };

  return cachedSecrets;
}

async function getGraphAccessToken({ azureClientId, azureClientSecret, tenantId }) {
  const postData = querystring.stringify({
    grant_type: "client_credentials",
    client_id: azureClientId,
    client_secret: azureClientSecret,
    scope: "https://graph.microsoft.com/.default"
  });

  const options = {
    hostname: "login.microsoftonline.com",
    path: `/${tenantId}/oauth2/v2.0/token`,
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Content-Length": Buffer.byteLength(postData)
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, res => {
      let body = "";
      res.on("data", chunk => (body += chunk));
      res.on("end", () => {
        try {
          const { access_token } = JSON.parse(body);
          if (!access_token) return reject(new Error("No access token in response"));
          resolve(access_token);
        } catch {
          reject(new Error("Failed to parse token response"));
        }
      });
    });

    req.on("error", reject);
    req.write(postData);
    req.end();
  });
}

async function getGroupNameFromGraph(groupId, graphToken) {
  const options = {
    hostname: "graph.microsoft.com",
    path: `/v1.0/groups/${groupId}`,
    method: "GET",
    headers: {
      Authorization: `Bearer ${graphToken}`
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, res => {
      let data = "";
      res.on("data", chunk => (data += chunk));
      res.on("end", () => {
        try {
          const result = JSON.parse(data);
          if (result.error) return reject(new Error(result.error.message));
          resolve(result.displayName);
        } catch {
          reject(new Error("Failed to parse group lookup response"));
        }
      });
    });

    req.on("error", reject);
    req.end();
  });
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

    const userGroups = decoded["groups"] || [];
    const userCustomGroups = decoded["custom:groups"]
      ? JSON.parse(decoded["custom:groups"])
      : [];

    const allGroups = [...userGroups, ...userCustomGroups];

    if (!allGroups.length) throw new Error("User not in any groups");

    const graphToken = await getGraphAccessToken(secrets);

    const groupNameMap = await Promise.all(
      allGroups.map(async (groupId) => {
        try {
          const name = await getGroupNameFromGraph(groupId, graphToken);
          return { id: groupId, name };
        } catch {
          return null;
        }
      })
    );

    const validGroups = groupNameMap.filter(Boolean);
    if (!validGroups.length) throw new Error("No valid group names resolved");

    return {
      principalId: decoded.sub || "user",
      policyDocument: {
        Version: "2012-10-17",
        Statement: [
          { Action: "execute-api:Invoke", Effect: "Allow", Resource: event.methodArn }
        ]
      },
      context: {
        "X-Group-IDs": validGroups.map(g => g.id).join(","),
        "X-Group-Names": validGroups.map(g => g.name).join(",")
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
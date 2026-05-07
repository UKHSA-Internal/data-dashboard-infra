const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const secretsClient = new SecretsManagerClient({});
let cachedSecrets = null;


async function getSecretApiKey() {
  if (cachedSecrets) return cachedSecrets;
  const credentials = await secretsClient.send(
    new GetSecretValueCommand({ SecretId: process.env.SECRETS_MANAGER_PRIVATE_API_KEY_ARN })
  );
  cachedSecrets = credentials.SecretString;
  return cachedSecrets;
}


async function getPermissionSets(apiKey, userId) {
    console.log("🕵️‍♀️ Inside getPermissionSets. UserID: ", userId)
    const baseURL = process.env.PRIVATE_API_URL;
    const targetURL = new URL(`/api/user/${userId}/permissions/hierarchy`, baseURL);
    const headers = { Authorization: apiKey,  'content-type': 'application/json' };
    const response = await fetch(targetURL, {method: 'GET', headers})
    console.log("🕵️‍♀️ Raw Response: ", response)
    console.log("🕵️‍♀️ json Response: ", response.json)
    const data = await response.json()
    console.log("Data: ", data)
    const { permission_sets } = data;
    console.log("🕵️‍♀️ Permission_Sets: ", permission_sets)
    return permission_sets;
}


async function handler(event) {
    const logMessage = `Received event: '${JSON.stringify(event)}'`;
    console.log(logMessage);

    const entraObjectId = event.request.userAttributes['custom:entraObjectId'];
    const apiKey = await getSecretApiKey();

    const permissionSets = await getPermissionSets(apiKey, entraObjectId);

    event.response = {
        claimsAndScopeOverrideDetails: {
            accessTokenGeneration: {
                claimsToAddOrOverride: {
                    entraObjectId,
                    permissionSets,
                },
            },
        },
    };
    const logMessage2 = `Updated token: '${JSON.stringify(event)}'`;
    console.log(logMessage2);
    return event;
}

module.exports = {
    handler,
    getPermissionSets,
}

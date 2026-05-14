import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

const secretsClient = new SecretsManagerClient({});
let cachedSecrets = null;
let sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function getSecretApiKey(useCache=true) {
    if (useCache && cachedSecrets) return cachedSecrets;
    const credentials = await secretsClient.send(
        new GetSecretValueCommand({ SecretId: process.env.SECRETS_MANAGER_PRIVATE_API_KEY_ARN })
    );
    cachedSecrets = credentials.SecretString;
    return cachedSecrets;
}

async function getPermissionSets(apiKey, userId) {
    const baseURL = process.env.PRIVATE_API_URL;
    const targetURL = new URL(`/api/user/${userId}/permissions/hierarchy`, baseURL);
    const headers = { Authorization: apiKey,  'content-type': 'application/json' };
    return fetch(targetURL, {method: 'GET', headers})
        .then(response => response?.ok
            ? response.json()
            : Promise.reject(response)) //throw if not 200-OK
        .then(json => {
            const { permission_sets } = json;
            return { permissionSets: permission_sets };
        }) //all good
        .catch(error => {
            console.log(`Error getting permission sets: ${error.status}: '${error.statusText}' for '${targetURL}'`);
            return { error };
        }) //handle errors
}

async function handler(event) {
    const logMessage = `Received event: '${JSON.stringify(event)}'`;
    console.log(logMessage);

    const entraObjectId = event.request.userAttributes['custom:entraObjectId'];
    let apiKey = await getSecretApiKey();

    let {error, permissionSets} = await getPermissionSets(apiKey, entraObjectId);
    if (error?.status == 401){
        console.log(`API key invalid, updating cached key...`);
        apiKey = await getSecretApiKey(false);
        let {error, permissionSets} = await getPermissionSets(apiKey, entraObjectId);
    } else if (error && error?.status != 200){
        console.log(`Error fetching permission sets, wait and retry:`);
        sleep(3000);
        console.log(`Retrying...`);
        let {error, permissionSets} = await getPermissionSets(apiKey, entraObjectId);
    }

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

export {
    handler,
    getPermissionSets
}


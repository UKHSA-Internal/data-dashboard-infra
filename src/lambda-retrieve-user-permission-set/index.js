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
            : Promise.reject(new Error(`Fetch error ${response.status}: ${response.statusText}`, { cause: response }))) //throw if not 200-OK
        .then(json => {
            const { permission_sets } = json;
            return { permissionSets: permission_sets };
        }) //all good
        .catch(error => {
            console.log(`Error getting permission sets: '${error.message}' for '${targetURL}'`);
            return { error };
        }) //handle errors
}

async function handler(event) {
    const logMessage = `Received event: '${JSON.stringify(event)}'`;
    console.log(logMessage);

    const entraObjectId = event.request.userAttributes['custom:entraObjectId'];
    let perfTestUuid;
    if (event.triggerSource == "TokenGeneration_ClientCredentials") {
        perfTestUuid = event.request.clientMetadata.user_uuid;
    }
    let apiKey = await getSecretApiKey();
    const userId = entraObjectId || perfTestUuid;

    let {error, permissionSets = []} = await getPermissionSets(apiKey, userId);
    if (error?.cause?.status == 401){
        apiKey = await getSecretApiKey(false);
        console.log(`Error '${error.message}' while fetching permission sets, retrying with updated API key...`);
        ({error, permissionSets = []} = await getPermissionSets(apiKey, userId));
    }
    if (error){
        sleep(3000);
        console.log(`Error '${error.message}' while fetching permission sets, retrying...`);
        ({permissionSets = []} = await getPermissionSets(apiKey, userId));
    }

    event.response = {
        claimsAndScopeOverrideDetails: {
            accessTokenGeneration: {
                claimsToAddOrOverride: {
                    entraObjectId: userId,
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


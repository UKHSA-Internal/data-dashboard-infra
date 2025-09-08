const {SecretsManagerClient, GetSecretValueCommand} = require("@aws-sdk/client-secrets-manager");

/**
 * Gets the secret for the revalidate secret from secrets manager
 *
 * @param {SecretsManagerClient} secretsManagerClient - An optional instance of the SecretsManagerClient
 *      to use for sending the command.
 * @returns {object} - The response from secrets manager
 */
async function getSecret(secretsManagerClient = new SecretsManagerClient()) {
    const input = {
        "SecretId": process.env.SECRETS_MANAGER_REVALIDATE_SECRET_ARN
    };
    const command = new GetSecretValueCommand(input);
    return secretsManagerClient.send(command);
}

/**
 * Retrieves the revalidate secret from secrets manager
 *
 * @param overridenDependencies - Object used to override the default dependencies.
 * @returns {string} - The revalidate secret
 */
async function getRevalidateSecretFromSecretsManager(overridenDependencies = {}) {
    const defaultDependencies = {getSecret};
    const dependencies = {...defaultDependencies, ...overridenDependencies}

    const response = await dependencies.getSecret()
    const secretJSON = JSON.parse(response.SecretString)
    return secretJSON.revalidate_secret
}

/**
 * Sends the complete request to api/revalidate in the frontend
 *
 * @param {string} revalidateSecret - The revalidate secret required to authenticate with the front end
 */
async function sendRevalidateRequest(revalidateSecret) {
    const baseURL = process.env.FRONT_END_URL
    const targetURL = new URL('/api/revalidate', baseURL)
    targetURL.searchParams.set('secret', revalidateSecret)
    return await fetch(targetURL, {method: 'POST'})
}


/**
 * Lambda handler function for revalidating the front end cache
 *
 * @param {Object} event - The event object triggered by the Lambda invocation.
 * @param overridenDependencies - Object used to override the default dependencies.
 */
async function handler(event, overridenDependencies = {}) {
    const defaultDependencies = {
        getRevalidateSecretFromSecretsManager,
        sendRevalidateRequest
    };
    const dependencies = {...defaultDependencies, ...overridenDependencies}

    console.log('Sending request to revalidate front end cache')
    const revalidateSecret = await dependencies.getRevalidateSecretFromSecretsManager()
    const response = await dependencies.sendRevalidateRequest(revalidateSecret)

    const data = await response.json()
    console.log(JSON.stringify(data))
    return data
}

module.exports = {
    handler,
    getSecret,
    getRevalidateSecretFromSecretsManager,
    sendRevalidateRequest,
}
const {SecretsManagerClient, GetSecretValueCommand} = require("@aws-sdk/client-secrets-manager");
const https = require('https');


/**
 * Gets the secret for the Slack webhook URL from secrets Manager
 *
 * @param {SecretsManagerClient} secretsManagerClient - An optional instance of the SecretsManagerClient
 *      to use for sending the command.
 * @returns {object} - The response from secrets manager
 */
async function getSecret(secretsManagerClient = new SecretsManagerClient()) {
    const input = {
        "SecretId": process.env.SECRETS_MANAGER_SLACK_WEBHOOK_URL_ARN
    };
    const command = new GetSecretValueCommand(input);
    return secretsManagerClient.send(command);
}

/**
 * Retrieves the Slack webhook URL from secrets manager
 *
 * @param overridenDependencies - Object used to override the default dependencies..
 * @returns {string} - The Slack webhook URL
 */
async function getSlackWebhookURLFromSecretsManager(overridenDependencies = {}) {
    const defaultDependencies = {getSecret};
    const dependencies = {...defaultDependencies, ...overridenDependencies}

    const response = await dependencies.getSecret()
    const secretJSON = JSON.parse(response.SecretString)
    return secretJSON.slack_webhook_url
}

/**
 * Consumes the inbound SNS message and builds the text to be sent to the Slack webhook URL
 *
 * @param {Object} event - The event object triggered by the Lambda invocation.
 * @returns {object} An enriched object to be used as the payload to the slack webhook URL
 */
function buildSlackPostFromSNSMessage(event) {
    const message = JSON.parse(event.Records[0].Sns.Message);
    return {
        text: `Alarm triggered: ${message.AlarmName}\nDescription: ${message.AlarmDescription}\nNew State: ${message.NewStateValue}\nSubject: ${event.Records[0].Sns.Subject}`,
        channel: '#ukhsa-data-dashboard-alerts'
    };
}

/**
 * Constructs the payload to be used in the request made to the Slack webhook URL
 *
 * @param overridenDependencies - Object used to override the default dependencies.
 * @returns {object} An enriched object to be used as the payload to the Slack webhook URL
 */
async function buildRequestOptions(overridenDependencies = {}) {
    const defaultDependencies = {getSlackWebhookURLFromSecretsManager};
    const dependencies = {...defaultDependencies, ...overridenDependencies}

    const webhookUrl = await dependencies.getSlackWebhookURLFromSecretsManager()
    return {
        method: 'POST',
        hostname: 'hooks.slack.com',
        path: new URL(webhookUrl).pathname,
    };
}

/**
 * Sends the given `requestOptions` and `slackMessage` to the Slack webhook URL
 *
 * @returns {object} An enriched object to be used as the payload to the Slack webhook URL
 */
async function submitMessageToSlack(requestOptions, slackMessage) {
    const request = https.request(requestOptions, (response) => {
        response.on('data', (data) => {
            process.stdout.write(data);
        });
    });

    request.on('error', (error) => {
        console.error(error);
    });

    request.write(JSON.stringify(slackMessage));
    request.end();
}

/**
 * Lambda handler function for consuming messages from SNS and sending notifications to Slack
 *
 * @param {Object} event - The event object triggered by the Lambda invocation.
 * @param overridenDependencies - Object used to override the default dependencies.
 */
async function handler(event, overridenDependencies = {}) {
    const defaultDependencies = {
        buildSlackPostFromSNSMessage,
        buildRequestOptions,
        submitMessageToSlack,
    };
    const dependencies = {...defaultDependencies, ...overridenDependencies}

    const slackMessage = dependencies.buildSlackPostFromSNSMessage(event)
    const requestOptions = dependencies.buildRequestOptions()
    await dependencies.submitMessageToSlack(requestOptions, slackMessage)
}

module.exports = {
    handler,
    getSecret,
    getSlackWebhookURLFromSecretsManager,
    submitMessageToSlack,
    buildRequestOptions,
    buildSlackPostFromSNSMessage
}
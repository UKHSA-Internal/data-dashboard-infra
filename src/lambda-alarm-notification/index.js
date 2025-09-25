const {SecretsManagerClient, GetSecretValueCommand} = require("@aws-sdk/client-secrets-manager");
const {IncomingWebhook} = require('@slack/webhook');

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
    const inboundSNSMessage = event.Records[0].Sns
    const lastColonIndex = inboundSNSMessage.TopicArn.lastIndexOf(':');
    const topicName = inboundSNSMessage.TopicArn.substring(lastColonIndex + 1);
    const message = JSON.parse(inboundSNSMessage.Message);

    return {
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": ":rotating_light: Alarm triggered",
                    "emoji": true
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "@here"
                }
            },
            {
                "type": "divider"
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": `*Alarm type:* ${message.AlarmName}`
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": `*Alarm description:* ${message.AlarmDescription}`
                }
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "plain_text",
                        "text": `State change reason: ${message.NewStateReason}`
                    }
                ]
            }
        ]
    }
}

/**
 * Sends the given `requestOptions` and `slackMessage` to the Slack webhook URL
 *
 * @param {Object} slackMessage - The object to be included in the Slack message payload
 * @param {string} webhookURL - The Slack webhook URL to send the message to
 */
async function submitMessageToSlack(slackMessage, webhookURL) {
    const webhook = new IncomingWebhook(webhookURL, {
        icon_emoji: ':rotating_light:', channel: '#ukhsa-data-dashboard-alerts'
    });
    await webhook.send(slackMessage)
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
        submitMessageToSlack,
        getSlackWebhookURLFromSecretsManager,
    };
    const dependencies = {...defaultDependencies, ...overridenDependencies}

    const webhookURL = await dependencies.getSlackWebhookURLFromSecretsManager()
    const slackMessage = dependencies.buildSlackPostFromSNSMessage(event)
    await dependencies.submitMessageToSlack(slackMessage, webhookURL)
}

module.exports = {
    handler, getSecret, getSlackWebhookURLFromSecretsManager, submitMessageToSlack, buildSlackPostFromSNSMessage
}
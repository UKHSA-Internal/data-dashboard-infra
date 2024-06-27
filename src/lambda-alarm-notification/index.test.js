const {
    buildSlackPostFromSNSMessage,
    getSecret,
    getSlackWebhookURLFromSecretsManager,
    submitMessageToSlack,
    handler,
} = require('./index.js')

const {IncomingWebhook} = require('@slack/webhook');
const sinon = require('sinon');

const {GetSecretValueCommand} = require("@aws-sdk/client-secrets-manager");

jest.mock('@slack/webhook');

const fakeSlackBaseURL = 'https://hooks.slack.com'
const fakeSlackWebhookURLPath = '/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'
const fakeSlackWebhookURL = `${fakeSlackBaseURL}${fakeSlackWebhookURLPath}`

describe('getSecret', () => {
    /**
     * Given the ARN of the secret associated with the Slack webhook URL
     * When `getSecret()` is called
     * Then the correct command is used when
     *  the `send` method is called from the `SecretsManagerClient`
     */
    test('Calls the secrets manager client with the correct command object', async () => {
        // Given
        const fakeSecretARN = 'fake-arn-for-secret';
        const mockedEnvVar = sinon.stub(process, 'env').value({SECRETS_MANAGER_SLACK_WEBHOOK_URL_ARN: fakeSecretARN});
        const secretsManagerClientSpy = {
            send: sinon.stub().resolves({}),
        }

        // When
        const result = await getSecret(secretsManagerClientSpy);

        // Then
        expect(secretsManagerClientSpy.send.calledWith(sinon.match.instanceOf(GetSecretValueCommand))).toBeTruthy()
        const argsCalledWithSpy = secretsManagerClientSpy.send.firstCall.args[0].input;
        expect(argsCalledWithSpy.SecretId).toEqual(fakeSecretARN);
        // Restore the environment variable
        mockedEnvVar.restore();
    });
});

describe('getSlackWebhookURLFromSecretsManager', () => {
    /**
     * Given the associated secret for the Slack webhook URL
     * When `getSlackWebhookURLFromSecretsManager()` is called
     * Then the call is delegated to the `getSecret()` function
     */
    test('should return the slack webhook URL when the secret is fetched successfully', async () => {
        // Given
        const mockSecretString = JSON.stringify({slack_webhook_url: fakeSlackWebhookURL});
        const mockGetSecret = jest.fn().mockResolvedValue({SecretString: mockSecretString});

        // When
        const result = await getSlackWebhookURLFromSecretsManager({getSecret: mockGetSecret});

        // Then
        expect(result).toBe(fakeSlackWebhookURL);
        expect(mockGetSecret).toHaveBeenCalled();
    });
});

describe('submitMessageToSlack', () => {
    const fakeSlackMessage = {text: 'fake-slack-message'};
    const sendMock = jest.fn();

    beforeEach(() => {
        IncomingWebhook.mockImplementation(() => ({
            send: sendMock
        }));
    });
    afterEach(() => {
        jest.clearAllMocks();
    });

    /**
     * Given a payload containing the Slack message
     * And a webhook URL
     * When the main `submitMessageToSlack()` is called
     * Then the call is delegated to the
     *  `IncomingWebhook` object from the `slack/webhook` library
     */
    test('should send a message to Slack', async () => {
        // Given
        sendMock.mockResolvedValue('Message sent');

        // When
        await expect(submitMessageToSlack(fakeSlackMessage, fakeSlackWebhookURL)).resolves.not.toThrow();

        // Then
        const expectedDefaultConstructorArgs = {
            icon_emoji: ':alert:',
            channel: '#ukhsa-data-dashboard-alerts'
        }
        expect(IncomingWebhook).toHaveBeenCalledWith(fakeSlackWebhookURL, expectedDefaultConstructorArgs);
        expect(sendMock).toHaveBeenCalledWith(fakeSlackMessage);
    });
});

describe('buildSlackPostFromSNSMessage', () => {
    const fakeEvent = {
        "Records": [{
            "EventSource": "aws:sns",
            "EventVersion": "1.0",
            "EventSubscriptionArn": "arn:aws:sns:region:account-id:topicname:subscription-id",
            "Sns": {
                "Type": "Notification",
                "MessageId": "message-id",
                "TopicArn": "arn:aws:sns:region:account-id:fake-topic-name",
                "Subject": "ALARM: \"4xxErrorRateHigh\" in AWS/CloudFront",
                "Message": "{\"AlarmName\":\"4xxErrorRateHigh\",\"AlarmDescription\":\"Alarm when 4xxErrorRate exceeds 1%\",\"AWSAccountId\":\"account-id\",\"NewStateValue\":\"ALARM\",\"NewStateReason\":\"Threshold Crossed: 1 datapoint [1.2345 (minimum)] was greater than or equal to the threshold (1.0).\",\"StateChangeTime\":\"2023-05-31T12:34:56.789Z\",\"Region\":\"US-East-1\",\"AlarmArn\":\"arn:aws:cloudwatch:region:account-id:alarm:4xxErrorRateHigh\",\"OldStateValue\":\"OK\",\"Trigger\":{\"MetricName\":\"4xxErrorRate\",\"Namespace\":\"AWS/CloudFront\",\"StatisticType\":\"Statistic\",\"Statistic\":\"MINIMUM\",\"Unit\":null,\"Dimensions\":[{\"name\":\"DistributionId\",\"value\":\"distribution-id\"}],\"Period\":300,\"EvaluationPeriods\":1,\"ComparisonOperator\":\"GreaterThanOrEqualToThreshold\",\"Threshold\":1.0,\"TreatMissingData\":\"- TreatMissingData: missing\",\"EvaluateLowSampleCountPercentile\":\"\"}}",
                "Timestamp": "2023-05-31T12:34:56.789Z",
                "SignatureVersion": "1",
                "Signature": "signature",
                "SigningCertUrl": "https://sns.region.amazonaws.com/SimpleNotificationService-xxxxxxxxxxxx.pem",
                "UnsubscribeUrl": "https://sns.region.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:region:account-id:topicname:subscription-id",
                "MessageAttributes": {}
            }
        }]
    }

    /**
     * Given an event passed to the lambda function from SNS
     * When `buildSlackPostFromSNSMessage()` is called
     * Then the correct message is extracted and built
     */
    test('should extract the correct message from the event', async () => {
        // Given / When
        const extractedMessage = buildSlackPostFromSNSMessage(fakeEvent)

        // Then
        const message = JSON.parse(fakeEvent.Records[0].Sns.Message)
        const expectedMessage = {
            blocks: [
                {
                    'type': 'header',
                    'text': {
                        'type': 'plain_text',
                        'text': ':alert: Alarm triggered @channel',
                        'emoji': true
                    }
                },
                {
                    'type': 'section',
                    'fields': [
                        {
                            'type': 'mrkdwn',
                            'text': `*Alarm type:*\n${message.AlarmName}`
                        },
                        {
                            'type': 'mrkdwn',
                            'text': `*Alarm description:*\n${message.AlarmDescription}`
                        }
                    ]
                },
                {
                    'type': 'section',
                    'fields': [
                        {
                            'type': 'mrkdwn',
                            'text': '*Subject:*\nALARM: "4xxErrorRateHigh" in AWS/CloudFront'
                        },
                        {
                            'type': 'mrkdwn',
                            'text': '*Source:*\nfake-topic-name'
                        }
                    ]
                }
            ]
        }
        expect(extractedMessage).toEqual(expectedMessage)
    });


});

describe('handler', () => {
    /**
     * Given no input
     * When the main `handler()` is called
     * Then the call is delegated to the
     *  `buildSlackPostFromSNSMessage(), `buildRequestOptions()`
     *  and `submitMessageToSlack()` functions
     */
    test('Orchestrates calls correctly', async () => {
        // Given
        // Injected dependencies to perform spy operations
        const expectedSlackMessage = sinon.stub()
        const buildSlackPostFromSNSMessageSpy = sinon.stub().returns(expectedSlackMessage);
        const expectedSlackWebhookUrl = sinon.stub()
        const getSlackWebhookURLFromSecretsManagerSpy = sinon.stub().returns(expectedSlackWebhookUrl);
        const submitMessageToSlackSpy = sinon.stub();
        const mockedEvent = sinon.stub()

        const spyDependencies = {
            buildSlackPostFromSNSMessage: buildSlackPostFromSNSMessageSpy,
            getSlackWebhookURLFromSecretsManager: getSlackWebhookURLFromSecretsManagerSpy,
            submitMessageToSlack: submitMessageToSlackSpy,
        }

        // When
        await handler(mockedEvent, spyDependencies)

        // Then
        expect(getSlackWebhookURLFromSecretsManagerSpy.calledOnce).toBeTruthy();
        expect(buildSlackPostFromSNSMessageSpy.calledWith(mockedEvent)).toBeTruthy()
        expect(submitMessageToSlackSpy.calledWith(expectedSlackMessage, expectedSlackWebhookUrl)).toBeTruthy();
    })
})

const {
    buildRequestOptions,
    buildSlackPostFromSNSMessage,
    getSecret,
    getSlackWebhookURLFromSecretsManager,
    submitMessageToSlack,
    handler,
} = require('./index.js')

const sinon = require('sinon');
const https = require('https');
const {GetSecretValueCommand} = require("@aws-sdk/client-secrets-manager");

jest.mock('https');

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
    let mockRequest;
    let mockResponse;

    beforeEach(() => {
        mockResponse = {
            on: jest.fn((event, callback) => {
                if (event === 'data') {
                    callback('mocked response data');
                }
            }),
        };
        mockRequest = {
            on: jest.fn(), write: jest.fn(), end: jest.fn(),
        };
        https.request.mockImplementation((options, callback) => {
            callback(mockResponse);
            return mockRequest;
        });
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    const fakeRequestOptions = {
        method: 'POST', hostname: 'hooks.slack.com', path: fakeSlackWebhookURLPath,
    };
    const fakeSlackMessage = {text: 'This is a test message for Slack'};

    /**
     * Given request options and a message to send to Slack
     * When `submitMessageToSlack()` is called
     * Then the correct data is written to the request
     */
    test('should write the message to the request', async () => {
        // Given / When
        await submitMessageToSlack(fakeRequestOptions, fakeSlackMessage);

        // Then
        expect(mockRequest.write).toHaveBeenCalledWith(JSON.stringify(fakeSlackMessage));
        expect(mockRequest.end).toHaveBeenCalled();
    });

    /**
     * Given request options and a message to send to Slack
     * And an error is expected to be thrown
     * When `submitMessageToSlack()` is called
     * Then the error is logged
     */
    test('should log an error if the request fails', async () => {
        // Given
        const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {
        });
        const error = new Error('Request failed');
        mockRequest.on.mockImplementationOnce((event, callback) => {
            if (event === 'error') {
                callback(error);
            }
        });

        // When
        await submitMessageToSlack(fakeRequestOptions, fakeSlackMessage);

        // Then
        expect(consoleErrorSpy).toHaveBeenCalledWith(error);
        consoleErrorSpy.mockRestore();
    });

    /**
     * Given request options and a message to send to Slack
     * When `submitMessageToSlack()` is called
     * Then the correct data is written to std out
     */
    test('should write the response data to stdout', async () => {
        // Given
        const processStdoutWriteSpy = jest.spyOn(process.stdout, 'write').mockImplementation(() => {
        });

        // When
        await submitMessageToSlack(fakeRequestOptions, fakeSlackMessage);

        // Then
        expect(processStdoutWriteSpy).toHaveBeenCalledWith('mocked response data');
        processStdoutWriteSpy.mockRestore();
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
                "TopicArn": "arn:aws:sns:region:account-id:topicname",
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
            text: `:alert: Alarm triggered: ${message.AlarmName}\nDescription: ${message.AlarmDescription}\nNew State: ${message.NewStateValue}\nSubject: ${fakeEvent.Records[0].Sns.Subject}`,
            channel: '#ukhsa-data-dashboard-alerts'
        }
        expect(extractedMessage).toEqual(expectedMessage)
    });


});

describe('buildRequestOptions', () => {
    /**
     * Given the `getSlackWebhookURLFromSecretsManager()` function
     *     which is mocked to retrieve the secret
     *     associated with the webhook URL
     * When `buildRequestOptions()` is called
     * Then the correct object is built and returned
     */
    test('Returns the correct object shape', async () => {
        // Given
        const mockedGetSlackWebHookURLFromSecretsManager = sinon.stub().resolves(fakeSlackWebhookURL)
        const injectedDependencies = {getSlackWebhookURLFromSecretsManager: mockedGetSlackWebHookURLFromSecretsManager}

        // When
        const requestOptions = await buildRequestOptions(injectedDependencies);

        // Then
        expect(requestOptions.method).toBe('POST');
        expect(requestOptions.hostname).toBe('hooks.slack.com');
        expect(requestOptions.path).toBe(fakeSlackWebhookURLPath);
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
        const expectedRequestOptions = sinon.stub()
        const buildRequestOptionsSpy = sinon.stub().returns(expectedRequestOptions);
        const submitMessageToSlackSpy = sinon.stub();
        const mockedEvent = sinon.stub()

        const spyDependencies = {
            buildSlackPostFromSNSMessage: buildSlackPostFromSNSMessageSpy,
            buildRequestOptions: buildRequestOptionsSpy,
            submitMessageToSlack: submitMessageToSlackSpy,
        }

        // When
        await handler(mockedEvent, spyDependencies)

        // Then
        expect(buildSlackPostFromSNSMessageSpy.calledWith(mockedEvent)).toBeTruthy()
        expect(buildRequestOptionsSpy.calledOnce).toBeTruthy();
        expect(submitMessageToSlackSpy.calledWith(expectedRequestOptions, expectedSlackMessage)).toBeTruthy();
    })
})

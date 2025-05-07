const {
    sendRevalidateRequest,
    getRevalidateSecretFromSecretsManager,
    getSecret,
    handler,
} = require('./index.js')
const sinon = require('sinon');

const {GetSecretValueCommand} = require("@aws-sdk/client-secrets-manager");

describe('getSecret', () => {
    /**
     * Given the ARN of the secret associated with the revalidate secret
     * When `getSecret()` is called
     * Then the correct command is used when
     *  the `send` method is called from the `SecretsManagerClient`
     */
    test('Calls the secrets manager client with the correct command object', async () => {
        // Given
        const fakeSecretARN = 'fake-arn-for-secret';
        const mockedEnvVar = sinon.stub(process, 'env').value({SECRETS_MANAGER_REVALIDATE_SECRET_ARN: fakeSecretARN});
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

describe('getRevalidateSecretFromSecretsManager', () => {
    /**
     * Given the associated secret for the revalidate secret
     * When `getRevalidateSecretFromSecretsManager()` is called
     * Then the call is delegated to the `getSecret()` function
     */
    test('should return the slack webhook URL when the secret is fetched successfully', async () => {
        // Given
        const fakeRevalidateSecret = "abc123"
        const mockSecretString = JSON.stringify({revalidate_secret: fakeRevalidateSecret});
        const mockGetSecret = jest.fn().mockResolvedValue({SecretString: mockSecretString});

        // When
        const result = await getRevalidateSecretFromSecretsManager({getSecret: mockGetSecret});

        // Then
        expect(result).toBe(fakeRevalidateSecret);
        expect(mockGetSecret).toHaveBeenCalled();
    });
});

describe('sendRevalidateRequest', () => {
    let mockedFetch;
    const revalidateSecret = 'abc123'

    beforeEach(() => {
        mockedFetch = jest.fn();
        global.fetch = mockedFetch;
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    test('Calls fetch with the correct args', async () => {
        // Given
        const fakeFrontendURL = 'https://fake-dashboard.gov.uk'
        const mockedEnvVar = sinon.stub(process, 'env').value({FRONT_END_URL: fakeFrontendURL});

        // When
        const response = await sendRevalidateRequest(revalidateSecret);

        // Then
        expect(mockedFetch).toHaveBeenCalledTimes(1);

        const mockedCall = mockedFetch.mock.lastCall
        const calledUrl = mockedCall[0];
        const expectedURL = `${fakeFrontendURL}/api/revalidate?secret=${revalidateSecret}`
        expect(calledUrl.toString()).toEqual(expectedURL);
        expect(mockedCall[1]).toEqual({"method": "POST"})

        expect(response).toEqual(mockedFetch.result)

        // Restore the environment variable
        mockedEnvVar.restore();
    });
});


describe('handler', () => {
    /**
     * Given no input
     * When the main `handler()` is called
     * Then the call is delegated to the
     *  `getRevalidateSecretFromSecretsManager()
     *  and `sendRevalidateRequest()` functions
     */
    test('Orchestrates calls correctly', async () => {
        // Given
        // Injected dependencies to perform spy operations
        const expectedRevalidateSecret = sinon.stub()
        const getRevalidateSecretFromSecretsManagerSpy = sinon.stub().returns(expectedRevalidateSecret);

        const fakeJSONResponse = {revalidated: true, now: Date.now()};
        const expectedResponse = {
            json: sinon.stub().resolves(fakeJSONResponse)
        };
        const sendRevalidateRequestSpy = sinon.stub().resolves(expectedResponse);

        const spyDependencies = {
            getRevalidateSecretFromSecretsManager: getRevalidateSecretFromSecretsManagerSpy,
            sendRevalidateRequest: sendRevalidateRequestSpy,
        }

        // When
        await handler(sinon.stub(), spyDependencies)

        // Then
        expect(getRevalidateSecretFromSecretsManagerSpy.calledOnce).toBeTruthy();
        expect(sendRevalidateRequestSpy.calledWith(expectedRevalidateSecret)).toBeTruthy()
    })
})

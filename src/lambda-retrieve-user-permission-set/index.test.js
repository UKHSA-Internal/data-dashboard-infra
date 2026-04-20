const {
    getPermissionSets,
    handler,
} = require('./index.js')
const sinon = require('sinon');


// Mocks AWS SecretsManager
jest.mock("@aws-sdk/client-secrets-manager", () => {
  const actual = jest.requireActual("@aws-sdk/client-secrets-manager");
  return {
    SecretsManagerClient: jest.fn(() => ({
      send: jest.fn((command) => {
        return Promise.resolve({
          SecretString: "API_KEY"
        });
      })
    })),
    GetSecretValueCommand: actual.GetSecretValueCommand
  };
});

const fakeAPIURL = 'https://fake-api.gov.uk'
const fakePermissionSet = [
    { "set_1": "data1" },
    { "set_2": "data2" },
] 
const fakeAPIResp = {
    "permission_sets": fakePermissionSet,
}
let mockedFetch;
let mockedEnvVar; 
beforeEach(() => {
    mockedFetch = jest.fn(
        () => Promise.resolve(
            {
                json: () => Promise.resolve(fakeAPIResp), 
            }
        ), 
    );
    globalThis.fetch = mockedFetch;
    mockedEnvVar = sinon.stub(process, 'env').value({PRIVATE_API_URL: fakeAPIURL});
});
afterEach(() => {
    jest.clearAllMocks();
    // Restore the environment variable
    mockedEnvVar.restore();
});


const fakeInputToken = {
    "callerContext": {
        "awsSdkVersion": "aws-sdk-unknown-unknown",
        "clientId": "4upd8frv3eo2cl9v746pc7b6aq"
    },
    "region": "eu-west-2",
    "request": {
        "groupConfiguration": {
            "groupsToOverride": [],
            "iamRolesToOverride": [],
            "preferredRole": null
        },
        "scopes": [
            "openid",
            "profile",
            "email"
        ],
        "userAttributes": {
            "custom:entraObjectId": "f6104f72-fe57-4726-a426-332e986be696",
            "cognito:user_status": "CONFIRMED",
            "email": "user.name@ukhsa.gov.uk",
            "email_verified": "true",
            "sub": "e6429214-e051-7098-998d-414acc8730a1"
        }
    },
    "response": {
        "claimsAndScopeOverrideDetails": null
    },
    "triggerSource": "TokenGeneration_HostedAuth",
    "userName": "e6429214-e051-7098-998d-414acc8730a1",
    "userPoolId": "eu-west-2_85TtaeD4r",
    "version": "3"
}

describe('getPermissionSets', () => {
    const userId = 'abc123'
    const apiKey = 'apikey'


    test('Calls fetch with the correct args', async () => {
        // Given

        // When
        const response = await getPermissionSets(apiKey, userId);

        // Then
        expect(mockedFetch).toHaveBeenCalledTimes(1);

        const mockedCall = mockedFetch.mock.lastCall
        const calledUrl = mockedCall[0];
        const expectedURL = `${fakeAPIURL}/api/user/${userId}/permissions/hierarchy`
        const headers = { Authorization: apiKey,  'content-type': 'application/json' };
        expect(calledUrl.toString()).toEqual(expectedURL);
        expect(mockedCall[1]).toEqual({"method": "GET", headers})
        expect(response).toEqual(fakePermissionSet)

    });
});


describe('handler', () => {
    /**
     * Given an input jwt
     * When `handler()` is called
     * Then the returned payload has an entraObjectId and permissionSets
     * added to response...claimsToAddOrOverride 
     */
    test('Token added to claims override', async () => {
        // Given
        const inputToken = JSON.parse(JSON.stringify(fakeInputToken))
        // When
        const result = await handler(inputToken);

        // Then
        expect(result.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.entraObjectId).toBe(inputToken.request.userAttributes['custom:entraObjectId'])
        expect(result.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.permissionSets).toBe(fakePermissionSet)
    })

    /**
     * Given an input jwt
     * When `handler()` is called
     * Then a log statement is recorded for the event
     * and a log statement is recorded for the updated token
     */
    test('Records log statement when event received', async () => {
        // Given
        const inputToken = JSON.parse(JSON.stringify(fakeInputToken))

        const logSpy = jest.spyOn(console, 'log');

        // When
        const result = await handler(inputToken);

        // Then
        const expectedFirstLogStatement = `Received event: '${JSON.stringify(fakeInputToken)}'`
        const expectedSecondLogStatement = `Updated token: '${JSON.stringify(result)}'`
        expect(logSpy).toHaveBeenCalledWith(expectedFirstLogStatement);
        expect(logSpy).toHaveBeenCalledWith(expectedSecondLogStatement);
    })

})

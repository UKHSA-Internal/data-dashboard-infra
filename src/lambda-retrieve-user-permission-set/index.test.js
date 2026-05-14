import {describe, expect, jest, test} from '@jest/globals';
import {mockClient} from 'aws-sdk-client-mock';
import {GetSecretValueCommand, SecretsManagerClient} from '@aws-sdk/client-secrets-manager';
import {getPermissionSets, handler} from './index.js';
import sinon from 'sinon';


const secretsMock = mockClient(SecretsManagerClient);
const fakeAPIKey = 'API_KEY';
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
    secretsMock.reset();
    secretsMock.on(GetSecretValueCommand).resolves({
        SecretString: fakeAPIKey,
    });
    mockedFetch = jest.fn(
        () => Promise.resolve(
            {
                ok: true,
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
        // const result = await getPermissionSets(apiKey, userId);
        // console.log(`Result: '${JSON.stringify(result)}'`);
        // const {error, permissionSets} = result;
        const {error, permissionSets} = await getPermissionSets(apiKey, userId);

        // Then
        expect(mockedFetch).toHaveBeenCalledTimes(1);

        const mockedCall = mockedFetch.mock.lastCall
        const calledUrl = mockedCall[0];
        const expectedURL = `${fakeAPIURL}/api/user/${userId}/permissions/hierarchy`
        const headers = { Authorization: apiKey,  'content-type': 'application/json' };
        expect(calledUrl.toString()).toEqual(expectedURL);
        expect(mockedCall[1]).toEqual({"method": "GET", headers})
        expect(permissionSets).toEqual(fakePermissionSet)

    });
});


describe('handler', () => {
    /**
     * Given an input jwt
     * When `handler()` is called multiple times
     * Then the secretsManager is only called once and the results are cached
     */
    test('Cached Secrets are used for subsequent requests', async () => {
        // Given
        const inputToken = JSON.parse(JSON.stringify(fakeInputToken))
        // When
        const result = await handler(inputToken);
        const result2 = await handler(inputToken);
        const result3 = await handler(inputToken);

        // Then
        expect(secretsMock.commandCalls(GetSecretValueCommand)).toHaveLength(1);
    })

    /**
     * Given an input jwt
     * When `handler()` is called and getPermissionSets receives a 401 error
     * Then the secretsManager is called again to update the API_KEY and 
     * getPermissionSets is called again with the update API_KEY
     */
    test('401 triggers updating API key and retry', async () => {
        // Given
        let mockedFetch401 = jest.fn(
            () => Promise.resolve(
                {
                    ok: false,
                    status: 401, 
                }
            ) 
        )
        globalThis.fetch = mockedFetch401;
        const logSpy = jest.spyOn(console, 'log');
        const inputToken = JSON.parse(JSON.stringify(fakeInputToken))

        // When
        const result = await handler(inputToken);

        // Then
        const expectedFirstLogStatement = `API key invalid, updating cached key...`
        expect(logSpy).toHaveBeenCalledWith(expectedFirstLogStatement);
    })
    /**
     * Given an input jwt
     * When `handler()` is called and getPermissionSets receives a 401 error
     * Then the secretsManager is called again to update the API_KEY and 
     * getPermissionSets is called again with the update API_KEY
     */
    beforeEach(() => {
        jest.useFakeTimers();
    });
    test('404 triggers sleep and retry', async () => {
        // Given
        let mockedFetch404 = jest.fn(
            () => Promise.resolve(
                {
                    ok: false,
                    status: 404, 
                }
            ) 
        )
        globalThis.fetch = mockedFetch404;
        const logSpy = jest.spyOn(console, 'log');
        const inputToken = JSON.parse(JSON.stringify(fakeInputToken))

        // When
        const result = await handler(inputToken);

        // Then
        const expectedFirstLogStatement = `Error fetching permission sets, wait and retry:`
        expect(logSpy).toHaveBeenCalledWith(expectedFirstLogStatement);
    })

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

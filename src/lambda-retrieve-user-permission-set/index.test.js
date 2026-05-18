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
            "entraObjectId": "11111111-2222-3333-abcd-444444444444",
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

    test('Calls fetch with the correct args', async () => {
        // Given
        const userId = 'abc123'
        const apiKey = 'apikey'

        // When
        const {permissionSets} = await getPermissionSets(apiKey, userId);

        // Then
        expect(mockedFetch).toHaveBeenCalledTimes(1);

        const mockedCall = mockedFetch.mock.lastCall
        const calledUrl = mockedCall[0];
        const calledArgs = mockedCall[1]
        const expectedURL = `${fakeAPIURL}/api/user/${userId}/permissions/hierarchy`
        const expectedHeaders = { Authorization: apiKey,  'content-type': 'application/json' };
        expect(calledUrl.toString()).toEqual(expectedURL);
        expect(calledArgs).toEqual({"method": "GET", "headers": expectedHeaders})
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
        const inputToken = structuredClone(fakeInputToken)
        // When
        await handler(inputToken);
        await handler(inputToken);
        await handler(inputToken);

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

        let mockedFetch401 = mockedFetch.mockImplementationOnce(
            () => Promise.resolve(
                {
                    ok: false,
                    status: 401, 
                    statusText: 'Not authenticated',
                }
            ) 
        )
        globalThis.fetch = mockedFetch401;
        const logSpy = jest.spyOn(console, 'log');
        const inputToken = structuredClone(fakeInputToken)

        // When
        await handler(inputToken);

        // Then
        const expectedFirstLogStatement = `Error 'Fetch error 401: Not authenticated' while fetching permission sets, retrying with updated API key...`
        expect(logSpy).toHaveBeenCalledWith(expectedFirstLogStatement);
    })

    /**
     * Given an input jwt
     * When `handler()` is called and getPermissionSets receives a non 200 response
     * Then getPermissionSets is retried and the token is still populated
     */
    beforeEach(() => {
        jest.useFakeTimers();
    });
    test('404 triggers sleep and retry', async () => {
        // Given
        let mockedFetch404 = mockedFetch.mockImplementationOnce(
            () => Promise.resolve(
                {
                    ok: false,
                    status: 404, 
                    statusText: 'Not found',
                }
            ) 
        )
        globalThis.fetch = mockedFetch404;
        const logSpy = jest.spyOn(console, 'log');
        const inputToken = structuredClone(fakeInputToken)

        // When
        const result = await handler(inputToken);

        // Then
        const expectedFirstLogStatement = `Error 'Fetch error 404: Not found' while fetching permission sets, retrying...`
        expect(logSpy).toHaveBeenCalledWith(expectedFirstLogStatement);
        expect(result.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.entraObjectId).toBe(inputToken.request.userAttributes['custom:entraObjectId'])
        expect(result.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.permissionSets).toBe(fakePermissionSet)
    })

    /**
     * Given an input jwt
     * When `handler()` is called and getPermissionSets receives a non 200 response
     * Then the token is populated with the user id and an empty permission set
     */
    beforeEach(() => {
        jest.useFakeTimers();
    });
    test('404 returns user id and empty permission set', async () => {
        // Given
        let mockedFetch404 = mockedFetch.mockImplementation(
            () => Promise.resolve(
                {
                    ok: false,
                    status: 404, 
                    statusText: 'Not found',
                }
            ) 
        )
        globalThis.fetch = mockedFetch404;
        const inputToken = structuredClone(fakeInputToken)

        // When
        const result = await handler(inputToken);

        // Then
        const expectedPermissionSets = []
        expect(result.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.entraObjectId).toBe(inputToken.request.userAttributes['custom:entraObjectId'])
        expect(result.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.permissionSets).toMatchObject(expectedPermissionSets)
    })

    /**
     * Given an input jwt
     * When `handler()` is called and getPermissionSets receives a 200 response
     * Then getPermissionSets is not retried
     */
    beforeEach(() => {
        jest.useFakeTimers();
    });
    test("200 doesn't trigger sleep and retry", async () => {
        // Given
        const logSpy = jest.spyOn(console, 'log');
        const inputToken = structuredClone(fakeInputToken)

        // When
        await handler(inputToken);

        // Then
        const expectedFirstLogStatement = `Error fetching permission sets, wait and retry:`
        expect(logSpy).not.toHaveBeenCalledWith(expectedFirstLogStatement);
    })

    /**
     * Given an input jwt
     * When `handler()` is called
     * Then the returned payload has an entraObjectId and permissionSets
     * added to response...claimsToAddOrOverride 
     */
    test('Token added to claims override', async () => {
        // Given
        const inputToken = structuredClone(fakeInputToken)
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
        const inputToken = structuredClone(fakeInputToken)

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

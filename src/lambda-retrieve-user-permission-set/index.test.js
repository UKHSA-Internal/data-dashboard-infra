import {describe, expect, jest, test} from '@jest/globals';
import {handler} from './index.js';


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

describe('handler', () => {
    /**
     * Given an input jwt
     * When `handler()` is called
     * Then the returned payload has an entraObjectId
     * added to response...claimsToAddOrOverride
     */
    test('Token added to claims override', async () => {
        // Given
        const inputToken = structuredClone(fakeInputToken)
        // When
        const result = await handler(inputToken);

        // Then
        expect(result.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.entraObjectId).toBe(inputToken.request.userAttributes['custom:entraObjectId'])
    })

    /**
     * Given an input jwt with a modified event to match performance testing input
     * When `handler()` is called 
     * Then the returned payload has an entraObjectId and permissionSets
     * added to response...claimsToAddOrOverride 
     */
    test('Perf Test Token added to claims override', async () => {
        // Given
        const inputToken = structuredClone(fakeInputToken)
        inputToken.triggerSource = "TokenGeneration_ClientCredentials"
        inputToken.request.clientMetadata = {"user_uuid": "9999-8888-7777-abcd-666666666666"}
        // When
        const result = await handler(inputToken);

        // Then
        expect(result.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.entraObjectId).toBe(inputToken.request.clientMetadata.user_uuid)
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

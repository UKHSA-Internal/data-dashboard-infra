const {
    handler
} = require('./index.js')
const uuid = require('uuid');


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


describe('handler', () => {
    /**
     * Given an input jwt
     * When `handler()` is called
     * Then the returned payload has a valid uuid added to 
     *   claim_uuid in response...claimsToAddOrOverride 
     */
    test('Token added to claims override', async () => {
        // Given
        const inputToken = JSON.parse(JSON.stringify(fakeInputToken))
        // When
        const result = await handler(inputToken);

        // Then
        expect(uuid.validate(result.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.claim_uuid)).toBeTruthy();
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

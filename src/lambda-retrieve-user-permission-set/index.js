import {v4} from 'uuid';

export default async function handler(event) {
    const logMessage = `Received event: '${JSON.stringify(event)}'`;
    console.log(logMessage);

    let dummy_claim = v4();

    event.response = {
        claimsAndScopeOverrideDetails: {
            accessTokenGeneration: {
                claimsToAddOrOverride: {
                    claim_uuid: dummy_claim,
                    entraObjectId: event.request.userAttributes['custom:entraObjectId'],
                },
            },
        },
    };
    const logMessage2 = `Updated token: '${JSON.stringify(event)}'`;
    console.log(logMessage2);
    return event;
}

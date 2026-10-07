async function handler(event) {
    console.log(`Received event: '${JSON.stringify(event)}'`);

    const entraObjectId = event.request.userAttributes['custom:entraObjectId'];
    let perfTestUuid;
    if (event.triggerSource === "TokenGeneration_ClientCredentials") {
        perfTestUuid = event.request.clientMetadata.user_uuid;
    }
    const userId = entraObjectId || perfTestUuid;
    event.response = {
        claimsAndScopeOverrideDetails: {
            accessTokenGeneration: {
                claimsToAddOrOverride: {
                    entraObjectId: userId,
                },
            },
        },
    };
    console.log(`Updated token: '${JSON.stringify(event)}'`);
    return event;
}

export {
    handler
}

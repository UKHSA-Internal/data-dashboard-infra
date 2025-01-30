exports.handler = async (event) => {
    console.log("Pre-signup Lambda invoked with event:", JSON.stringify(event, null, 2));

    // Auto-confirm user and verify email
    event.response.autoConfirmUser = true;
    event.response.autoVerifyEmail = true;

    return event;
};
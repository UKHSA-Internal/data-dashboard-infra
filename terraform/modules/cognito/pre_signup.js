exports.handler = async (event) => {
    console.log("Pre-signup Lambda invoked with event:", JSON.stringify(event, null, 2));

    // Check if the email attribute exists before auto-verifying
    if (event.request.userAttributes && event.request.userAttributes.email) {
        event.response.autoVerifyEmail = true;
    } else {
        console.log("No email provided. Skipping auto-verification.");
    }

    // auto-confirm the user
    event.response.autoConfirmUser = true;

    return event;
};
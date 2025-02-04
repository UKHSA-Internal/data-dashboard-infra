exports.handler = async (event) => {
    console.log("Post-auth Lambda invoked with event:", JSON.stringify(event, null, 2));

    try {
        console.log("Trigger source:", event.triggerSource);
        console.log("User Pool ID:", event.userPoolId);
        console.log("User Name:", event.userName);

        if (event.request.userAttributes) {
            console.log("User attributes:", JSON.stringify(event.request.userAttributes, null, 2));
        } else {
            console.log("No user attributes provided in the event.");
        }

        console.log("Environment variables:", process.env);

        if (event.triggerSource !== 'PostAuthentication_Authentication') {
            console.warn("Unexpected trigger source:", event.triggerSource);
        }

        console.log("Response being returned:", JSON.stringify(event.response, null, 2));
        return event;
    } catch (error) {
        console.error("Error in Post-auth Lambda:", error);
        throw error;
    }
};
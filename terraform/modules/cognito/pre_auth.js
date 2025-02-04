exports.handler = async (event) => {
    console.log("Pre-auth Lambda invoked with event:", JSON.stringify(event));
    return event;
};
exports.handler = async (event) => {
    console.log("Post-auth Lambda invoked with event:", JSON.stringify(event));
    return event;
};
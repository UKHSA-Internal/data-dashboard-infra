exports.handler = async (event) => {
    console.log("Pre-signup Lambda invoked with event:", JSON.stringify(event));
    return event;
};
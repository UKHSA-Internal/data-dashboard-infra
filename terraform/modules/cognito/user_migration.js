exports.handler = async (event) => {
    console.log("User migration Lambda invoked with event:", JSON.stringify(event));
    return event;
};
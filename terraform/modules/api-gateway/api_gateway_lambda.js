exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event, null, 2));

    return {
        statusCode: 200,
        body: JSON.stringify({ message: "Hello from API Gateway via Lambda!" }),
        headers: {
            "Content-Type": "application/json"
        }
    };
};
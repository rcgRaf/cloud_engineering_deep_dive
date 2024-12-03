exports.handler = async (event) => {
    console.log("Hello World", event.message);
    console.log(`Received event: ${stringify(event)}`);
    return {
        statusCode: 200,
        body: JSON.stringify('Hello World from V4!'),
    };
};
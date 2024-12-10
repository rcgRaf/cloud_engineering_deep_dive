const AWS = require('aws-sdk');
const dynamoDB = new AWS.DynamoDB.DocumentClient();

const TABLE_NAME = process.env.DYNAMODB_TABLE;

exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  const processedEvents = [];

  for (const record of event.Records) {
    try {
      // Parse the message body
      const messageBody = JSON.parse(record.body);
      const { event_id, event_data } = messageBody;

      if (!event_id) {
        console.warn(`Skipping record with missing event_id: ${record.body}`);
        continue;
      }

      // Write the new event to DynamoDB
      await writeEventToDynamoDB(event_id, event_data);

      console.log(`Processed and stored event_id: ${event_id}`);
      processedEvents.push(event_id);

    } catch (error) {
      console.error(`Error processing record: ${JSON.stringify(record)}`, error);
    }
  }

  console.log(`Successfully processed events: ${processedEvents}`);
  return {
    statusCode: 200,
    body: `Processed ${processedEvents.length} events`,
  };
};

async function writeEventToDynamoDB(event_id, data) {
  const ttl = 600; // 10 mins in seconds
  const params = {
    TableName: TABLE_NAME,
    Item: {
      event_id,
      data,
      ttl,
    },
    ConditionExpression: "attribute_not_exists(event_id)"
  };

  try {
    await dynamoDB.put(params).promise();
  } catch (error) {
    if (error.code === "ConditionalCheckFailedException") {
      console.log(`Item with event id ${event_id} already exists. Skipping...`);
    }
    else {
      console.error(`Error writing event to DynamoDB for event_id: ${event_id}`, error);
    }
    throw error;
  }
}

exports.handler = async (event) => {
  try {
      console.log("DynamoDB Stream event received:", JSON.stringify(event, null, 2));

      for (const record of event.Records) {
          console.log(`Processing record: ${JSON.stringify(record, null, 2)}`);

          // Check the type of operation: INSERT, MODIFY, REMOVE
          if (record.eventName === "INSERT") {
              console.log("New item added:");
              console.log(JSON.stringify(record.dynamodb.NewImage));
          } else if (record.eventName === "MODIFY") {
              console.log("Item modified:");
              console.log("Before:", JSON.stringify(record.dynamodb.OldImage));
              console.log("After:", JSON.stringify(record.dynamodb.NewImage));
          } else if (record.eventName === "REMOVE") {
              console.log("Item removed:");
              console.log(JSON.stringify(record.dynamodb.OldImage));
          }
      }

      return { statusCode: 200, body: "Success" };
  } catch (err) {
      console.error("Error processing DynamoDB stream:", err);
      throw new Error("Error processing DynamoDB stream");
  }
};
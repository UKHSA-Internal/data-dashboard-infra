const {S3Client, GetObjectCommand} = require("@aws-sdk/client-s3");
const {KinesisClient, PutRecordCommand} = require("@aws-sdk/client-kinesis");
const uuid = require('uuid');


/**
 * Returns the s3 bucket name and object key from the given event.
 *
 * @param {Object} event - The event object triggered by the Lambda invocation.
 * @returns {Object} An object containing the extracted bucket name and object key.
 */
function extractBucketAndObjectKey(event) {
    const record = event.Records[0].s3;
    const bucket = record.bucket.name;
    let key = record.object.key;

    // Decode special characters in the object key name
    // because S3 URL encodes object key names implicitly
    key = decodeURIComponent(key);

    return {bucket, key};
}

/**
 * Downloads the file from the S3 bucket.
 *
 * @param {string} bucket - The name of the S3 bucket.
 * @param {string} key - The key (path) of the object in the S3 bucket.
 * @param {S3Client} s3Client - An optional instance of the S3Client to use for sending the command.
 * @returns {Object} - The parsed JSON content of the downloaded file.
 */
async function downloadFileFromS3(bucket, key, s3Client = new S3Client()) {
    const command = new GetObjectCommand({
        Bucket: bucket,
        Key: key
    });
    const response = await s3Client.send(command);

    const responseBody = await response.Body.transformToString()
    return JSON.parse(responseBody);
}


/**
 * Builds a serialized payload which can be written as a record to Kinesis
 *
 * @param {string} key - The full S3 object key for the data
 * @param {Object} fileContents - The parsed JSON content of the downloaded file.
 * @returns {Object} - The serialized JSON payload
 */
function constructPayload(key, fileContents) {
    return JSON.stringify({
        name: key, data: fileContents,
    });
}


/**
 * Writes the data in the payload as a record to the Kinesis stream.
 *
 * @param {string} payload - The JSON serialized data payload
 * @param {KinesisClient} kinesisClient - An optional instance of the KinesisClient to use for sending the command.
 * @returns {Promise} A promise that resolves once the record has been successfully written to the Kinesis stream.
 */
async function writeDataToKinesis(payload, kinesisClient = new KinesisClient()) {
    const command = new PutRecordCommand({
        StreamName: process.env.KINESIS_DATA_STREAM_NAME,
        Data: Buffer.from(payload),
        PartitionKey: uuid.v4(),
    })
    await kinesisClient.send(command);
}


/**
 * Lambda handler function for downloading the file from S3 and publishing the corresponding record to Kinesis.
 *
 * @param {Object} event - The event object triggered by the Lambda invocation.
 * @param {Object} context - The Lambda execution context.
 * @param overridenDependencies - Object used to override the default dependencies.
 * @throws {Error} - Throws an error if there are issues during file download or Kinesis publishing.
 */
async function handler(event, context, overridenDependencies = {}) {
    const defaultDependencies = {
        extractBucketAndObjectKey,
        downloadFileFromS3,
        constructPayload,
        writeDataToKinesis
    };
    const dependencies = {...defaultDependencies, ...overridenDependencies};

    const {bucket, key} = dependencies.extractBucketAndObjectKey(event)
    const fileContents = await dependencies.downloadFileFromS3(bucket, key)

    const payload = dependencies.constructPayload(key, fileContents)

    await dependencies.writeDataToKinesis(payload)

    const logMessage = `Record for '${key}' published to Kinesis`;
    console.log(logMessage);
}

module.exports = {
    extractBucketAndObjectKey,
    downloadFileFromS3,
    writeDataToKinesis,
    constructPayload,
    handler,
}
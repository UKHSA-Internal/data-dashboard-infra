const {
    S3Client,
    GetObjectCommand,
    ListObjectsV2Command,
    ListObjectsV2CommandOutput,
    GetObjectCommandOutput
} = require("@aws-sdk/client-s3");
const {SecretsManagerClient, GetSecretValueCommand} = require("@aws-sdk/client-secrets-manager");
const {WebClient} = require("@slack/web-api")
const axios = require('axios');
const FormData = require('form-data');
const path = require('path');

const S3_CANARY_LOGS_BUCKET_NAME = process.env.S3_CANARY_LOGS_BUCKET_NAME;

/**
 * Gets the filename associated with the s3 key / file path
 *
 * @param {string} filePath - The full filepath / s3 key for the files
 * @returns {string} - The extracted filename
 */
function getFilename(filePath) {
    return path.basename(filePath);
}

/**
 * Gets the secret for the Slack webhook URL from SecretsManager
 *
 * @param {SecretsManagerClient} secretsManagerClient - An instance of the SecretsManagerClient
 *      to use for sending the command.
 * @returns {object} - The response from secrets manager
 */
async function getSecret(secretsManagerClient) {
    const input = {
        "SecretId": process.env.SECRETS_MANAGER_SLACK_WEBHOOK_URL_ARN
    };
    const command = new GetSecretValueCommand(input);
    return secretsManagerClient.send(command);
}

/**
 * Gets and parses the secret for the Slack webhook URL from SecretsManager
 *
 * @param {SecretsManagerClient} secretsManagerClient - An optional instance of the SecretsManagerClient
 *      to use for sending the command.
 * @returns {object} - The JSON object representing the secret
 */
async function getSlackSecret(secretsManagerClient = new SecretsManagerClient()) {
    const response = await getSecret(secretsManagerClient)
    return JSON.parse(response.SecretString)
}

/**
 * Lists all the files in the s3 bucket which contain the given prefix
 *
 * @param {string} bucket - The name of the S3 bucket.
 * @param {string} prefix - The prefix to filter objects by in the S3 bucket.
 * @param {S3Client} s3Client - An optional instance of the S3Client to use for sending the command.
 * @returns {ListObjectsV2CommandOutput} - The response from the underlying `ListObjectsV2Command` call.
 */
async function listFiles(bucket, prefix, s3Client = new S3Client()) {
    const command = new ListObjectsV2Command({
        Bucket: bucket, Prefix: prefix
    });
    return s3Client.send(command);
}

/**
 * Creates a file `Buffer` from the given `stream`
 *
 * @param {object} stream - The filestream to be opened.
 * @returns {Promise} - The Promise object wrapping the created file buffer.
 */
const streamToBuffer = async (stream) => {
    return new Promise((resolve, reject) => {
        const chunks = [];
        stream.on('data', (chunk) => chunks.push(chunk));
        stream.on('end', () => resolve(Buffer.concat(chunks)));
        stream.on('error', reject);
    });
};

/**
 * Downloads the given file from the s3 bucket
 *
 * @param {string} bucket - The name of the S3 bucket.
 * @param {string} key - The key associated with the target file being downloaded from the S3 bucket.
 * @param {S3Client} s3Client - An optional instance of the S3Client to use for sending the command.
 * @returns {GetObjectCommandOutput} - The response from the underlying `GetObjectCommand` call.
 */
async function downloadFile(bucket, key, s3Client = new S3Client()) {
    const command = new GetObjectCommand({
        Bucket: bucket, Key: key
    });
    return s3Client.send(command);
}

/**
 * Downloads the given file from the s3 bucket
 *
 * @param {string} bucket - The name of the S3 bucket.
 * @param {array} keys - The keys associated with the target files being downloaded from the S3 bucket.
 * @param {S3Client} s3Client - An optional instance of the S3Client to use for sending the command.
 * @returns {array} - A list of objects containing
 *  {key: <the downloadable key>: content: The individual download responses}
 */
async function downloadAllFiles(keys, bucket, s3Client = new S3Client()) {
    const results = [];

    for (let key of keys) {
        let content = await downloadFile(bucket, key, s3Client);
        results.push({"key": key, "content": content});
    }
    return results;
}

/**
 * Sets up the `WebClient` object used to interact with Slack.
 *
 * @param {string} token - The token associated with the Slack bot.
 * @returns {WebClient} - An instantiated `WebClient` instance used to interact with Slack.
 */
function buildSlackClient(token) {
    return new WebClient(token);
}

/**
 * Gets a URL from the Slack API to upload the file to.
 *
 * @param {WebClient} slackClient - The `WebClient` instance used to interact with Slack.
 * @param {string} filename - The name of the file being uploaded to Slack.
 * @param {number} length - Size in bytes of the file being uploaded.
 * @returns {Object} - The response from the underlying `WebClient.files.getUploadURLExternal` call.
 */
async function getFileUploadURLToSlack(slackClient, filename, length) {
    return slackClient.files.getUploadURLExternal({
        token: slackClient.token, filename: filename, length: length
    });
};

/**
 * Sends a POST request to the given url containing the given `fileBufferStream`.
 *
 * @param {string} url - The URL to POST the file to.
 * @param {string} filename - The name of the file being uploaded.
 * @param {Buffer} fileBufferStream - Size in bytes of the file being uploaded.
 * @returns {Promise} - The promise from the underlying POST request call
 */
async function sendPostRequest(url, filename, fileBufferStream) {
    try {
        const form = new FormData();
        form.append('file', fileBufferStream, {filename});
        await axios.post(url, form, {
            headers: {...form.getHeaders()}
        });
    } catch (error) {
        console.error('Error sending POST request:', error.message);
    }
}

/**
 * Finishes an upload to Slack started with a `WebClient.files.getUploadURLExternal` call
 *
 * @param {WebClient} slackClient - The `WebClient` instance used to interact with Slack.
 * @param {array} files - Array of file ids and their corresponding (optional) titles.
 * @param {string} channelId - The ID associated with the channel which the image is being sent to.
 * @param {string} threadTs - The ID of the parent thread to attach this image as a reply to.
 * @returns {Object} - The response from the underlying `WebClient.files.completeUploadExternal` call.
 */
async function completeFileUploadToSlack(slackClient, files, channelId, threadTs) {
    return slackClient.files.completeUploadExternal({
        token: slackClient.token, files: files, channel_id: channelId, thread_ts: threadTs,
    });
}

/**
 * Extracts the directory from the given full s3 object key
 *
 * @param {string} filePath - The `s3 object key / filepath to extract the directory from
 * @returns {string} - The preceding file directory associated with the given full s3 object key.
 */
function getDirectoryPath(filePath) {
    const parts = filePath.split('/');
    parts.pop();
    return parts.join('/');
}

/**
 * Gets the current datetime containing the year, month, day and hour. The month, day and hours are padded to 2 digits.
 *
 * @returns {object} - The year, month, day, hour values returned as padded strings.
 *   e.g. The date of 5th Aug 2024 at 1pm is returned as:
 *   >>> {'2024', '08', '05', '13'}
 */
function getCurrentDate() {
    const currentDate = new Date();
    const year = String(currentDate.getFullYear());
    const month = String(currentDate.getMonth() + 1).padStart(2, '0');
    const day = String(currentDate.getDate()).padStart(2, '0');
    const hour = String(currentDate.getHours()).padStart(2, '0');
    return {year, month, day, hour}
}

/**
 * Gets the target folder/prefix in the s3 bucket for the required files
 *
 * @param {string} target - The mid-prefix / canary name to filter against.
 * @param {S3Client} s3Client - An optional instance of the S3Client to use for sending the command.
 * @returns {string} - The relevant prefix for the required files in the s3 bucket
 */
async function getRelevantPrefix(target, s3Client = new S3Client()) {
    const {year, month, day, hour} = getCurrentDate()
    const prefix = `canary/eu-west-2/${target}/${year}/${month}/${day}/${hour}`
    try {
        const data = await listFiles(S3_CANARY_LOGS_BUCKET_NAME, prefix, s3Client)

        const folders = new Set(data.Contents.map(item => {
            const parts = item.Key.split('/');
            return parts.slice(0, 9).join('/');
        }));

        const folderArray = Array.from(folders);

        folderArray.sort((a, b) => (a < b ? 1 : -1));
        return getDirectoryPath(folderArray[0])
    } catch (error) {
        console.error('Error fetching the latest folder:', error);
        throw error;
    }
}

/**
 * Extracts the keys associated with the failed page snapshots from the given keys
 *
 * @param {array} keys - Array of objects representing each of the keys in the s3 folder/prefix
 * @returns {array} - Arrays of strings representing the keys of the failed page snapshots.
 */
function extractFailedScreenshotKeys(keys) {
    return keys
        .filter(item => item.Key.includes('-failed') && item.Key.endsWith('.png'))
        .map(item => item.Key);
}

/**
 * Extracts the file associated with the given key from the given keys
 *
 * @param {array} keys - Array of objects representing each of the keys in the s3 folder/prefix
 * @param {string} keyToSearchFor - The key to filter for in the given `keys`
 *
 * @returns {string} - The key associated with the given `keyToSearchFor`
 */
function extractReportKey(keys, keyToSearchFor) {
    const reportKeys = keys
        .filter(item => item.Key.includes(keyToSearchFor))
        .map(item => item.Key);
    return reportKeys[0]
}

/**
 * Builds the `blocks` to be sent to the Slack API to post the primary message.
 *
 * @param {string} target - The name of the canary from which the alarm was raised.
 * @param {string} startTime - The time which the canary started its run.
 * @param {string} endTime - The time which the canary completed its run.
 * @param {array} brokenLinks - Array of strings, each of which represents a broken link
 *
 * @returns {array} - An array of JSON objects which can be used to post to the Slack channel with.
 */
function buildSlackPostPayload(target, startTime, endTime, brokenLinks) {
    return [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": ":alert: Canary run failed",
                "emoji": true
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": `*Alarm name:*\n${target}`
            }
        },
        buildBrokenLinksList(brokenLinks),
        {
            "type": "context",
            "elements": [
                {
                    "type": "plain_text",
                    "text": `Canary started at ${startTime} and failed at ${endTime}`
                }
            ]
        },
    ]
}

/**
 * Builds the `blocks` to be sent to the Slack API for the broken links bullet point list
 *
 * @param {array} brokenLinks - Array of strings, each of which represents a broken link
 *
 * @returns {object} - JSON object which can be used to post to the Slack channel with.
 */
function buildBrokenLinksList(brokenLinks) {
    const blocks = {
        "type": "rich_text",
        "elements": [
            {
                "type": "rich_text_section",
                "elements": [
                    {
                        "type": "text",
                        "text": "Detected broken link(s):\n"
                    },
                ]
            },
            {
                "type": "rich_text_list",
                "style": "bullet",
                "indent": 0,
                "border": 0,
                "elements": []
            }
        ]
    }
    brokenLinks.forEach(brokenLink => {
        blocks.elements[1].elements.push(
            {
                "type": "rich_text_section",
                "elements": [
                    {
                        "type": "link",
                        "url": brokenLink
                    }
                ]
            },
        );
    });

    return blocks
}

/**
 * Uploads the downloaded file to the given Slack channel under the parent thread as an individual reply.
 *
 * @param {object} downloadedFileResponse - The object containing the key of file and the `GetObjectCommandResponse`
 * @param {WebClient} slackClient - The `WebClient` instance used to interact with Slack.
 * @param {string} channelId - The ID associated with the channel which the image is being sent to.
 * @param {string} threadTs - The ID of the parent thread to attach this image as a reply to.
 *
 * @returns {Promise} - The promise from the function call
 */
async function uploadScreenshotToSlackThread(downloadedFileResponse, slackClient, channelId, threadTs) {
    const fileBufferStream = await streamToBuffer(downloadedFileResponse.content.Body);
    const fileName = getFilename(downloadedFileResponse.key);
    const fileUploadURLResponse = await getFileUploadURLToSlack(slackClient, fileName, fileBufferStream.length)

    const uploadURL = fileUploadURLResponse.upload_url
    const fileID = fileUploadURLResponse.file_id

    await sendPostRequest(uploadURL, fileName, fileBufferStream)
    const files = [{"id": fileID, "title": fileName}]
    await completeFileUploadToSlack(slackClient, files, channelId, threadTs)
}

/**
 * Uploads the downloaded files to the given Slack channel under the parent thread as an individual reply.
 *
 * @param {array} downloadedFileResponses - The objects containing the key of each file and `GetObjectCommandResponse`
 * @param {WebClient} slackClient - The `WebClient` instance used to interact with Slack.
 * @param {string} channelId - The ID associated with the channel which the image is being sent to.
 * @param {string} threadTs - The ID of the parent thread to attach this image as a reply to.
 *
 * @returns {Promise} - The promise from the function call
 */
async function uploadAllScreenshotsToSlackThread(downloadedFileResponses, slackClient, channelId, threadTs) {
    for (let downloadedFileResponse of downloadedFileResponses) {
        await uploadScreenshotToSlackThread(downloadedFileResponse, slackClient, channelId, threadTs)
    }
}

/**
 * Posts a primary/parent message to Slack
 *
 * @param {WebClient} slackClient - The `WebClient` instance used to interact with Slack.
 * @param {array} payload - The `blocks` payload to send with the message.
 * @param {string} channelId - The ID associated with the channel which the image is being sent to.
 * @returns {Object} - The response from the underlying `WebClient.chat.postMessage` call.
 */
async function sendSlackPost(slackClient, payload, channelId) {
    return await slackClient.chat.postMessage({
        token: slackClient.token, channel: channelId, blocks: payload, text: 'Synthetic monitoring alert raised',
    });
}

/**
 * Extracts the contents of the report file from the given `folderContents`
 *
 * @param {array} folderContents - Array of objects representing the listed folder contents
 * @param {string} keyToSearchFor - The key to filter for in the given `keys`
 *
 * @returns {object} - The JSON representation of the contents of the report file.
 */
async function extractReport(folderContents, keyToSearchFor) {
    const downloadedReportKey = extractReportKey(folderContents, keyToSearchFor)
    const downloadedReportResponse = await downloadFile(S3_CANARY_LOGS_BUCKET_NAME, downloadedReportKey)

    const reportFileBuffer = await streamToBuffer(downloadedReportResponse.Body);

    const jsonString = reportFileBuffer.toString('utf8');
    return JSON.parse(jsonString);
}

/**
 * Extracts the name of the triggered Canary from the `event` object passed to the Lambda runtime.
 *
 * @param {object} event - The object passed down to the Lambda runtime on initialization.
 * @returns {string} - The name of the Canary being triggered.
 */
function extractTargetFromEvent(event) {
    const eventMessage = JSON.parse(event.Records[0].Sns.Message);
    return eventMessage.Trigger.Dimensions[0].value
}

/**
 * Calculates the relevant folder in s3 relating to the triggered Canary results.
 *
 * @param {object} event - The object passed down to the Lambda runtime on initialization.
 * @returns {string} - The prefix associated with the 'folder' of the triggered Canary results.
 */
async function determineRelevantFolderInS3(event) {
    const target = extractTargetFromEvent(event)
    return await getRelevantPrefix(target)
}

/**
 * Main handler entrypoint for the Lambda runtime execution.
 *
 * @param {object} event - The object passed down to the Lambda runtime on initialization.
 */
async function handler(event) {
    const relevantFolder = await determineRelevantFolderInS3(event)
    const slackSecret = await getSlackSecret()

    const slackClient = await buildSlackClient(slackSecret.slack_token)

    const listedFiles = await listFiles(S3_CANARY_LOGS_BUCKET_NAME, relevantFolder)
    const folderContents = listedFiles.Contents

    const syntheticsReport = await extractReport(folderContents, 'SyntheticsReport')
    const brokenLinksReport = await extractReport(folderContents, 'BrokenLinkCheckerReport')

    const slackPayload = buildSlackPostPayload(
        syntheticsReport.canaryName,
        syntheticsReport.startTime,
        syntheticsReport.endTime,
        brokenLinksReport.brokenLinks
    )
    const slackPostResponse = await sendSlackPost(slackClient, slackPayload, slackSecret.slack_channel_id)

    const extractedSnapshotKeys = extractFailedScreenshotKeys(folderContents)

    const downloadResponses = await downloadAllFiles(extractedSnapshotKeys, S3_CANARY_LOGS_BUCKET_NAME)
    await uploadAllScreenshotsToSlackThread(downloadResponses, slackClient, slackSecret.slack_channel_id, slackPostResponse.ts)
}

module.exports = {
    handler
}
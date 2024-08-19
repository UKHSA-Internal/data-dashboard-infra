const {GetObjectCommand, ListObjectsV2Command} = require("@aws-sdk/client-s3");
const axios = require('axios');
const FormData = require('form-data');
const path = require('path');
const sinon = require("sinon");
const {GetSecretValueCommand} = require("@aws-sdk/client-secrets-manager");
const index = require("./index");
const {GetCanaryRunsCommand} = require("@aws-sdk/client-synthetics");

// Mock dependencies
jest.mock('axios');
jest.mock('form-data');
jest.mock('path');

describe('getFilename', () => {
    /**
     * Given a file path
     * When `getFilename` is called
     * Then it should return the correct file name
     */
    test('Extracts the filename from the file path', () => {
        // Given
        const filePath = 'folder/subfolder/02-covid-19-failed.png';
        path.basename.mockReturnValue('02-covid-19-failed.png');

        // When
        const result = index.getFilename(filePath);

        // Then
        expect(result).toBe('02-covid-19-failed.png');
        expect(path.basename).toHaveBeenCalledWith(filePath);
    });
});

describe('getSecret', () => {
    /**
     * Given the ARN of the secret associated with the Slack webhook URL
     * When `getSecret()` is called
     * Then the correct command is used when
     *  the `send` method is called from the `SecretsManagerClient`
     */
    test('Gets the secret from SecretsManager', async () => {
        // Given
        const fakeSecretARN = 'fake-arn-for-secret';
        const mockedEnvVar = sinon.stub(process, 'env').value({SECRETS_MANAGER_SLACK_WEBHOOK_URL_ARN: fakeSecretARN});
        const spySecretsManagerClient = {
            send: sinon.stub().resolves({}),
        }

        // When
        await index.getSecret(spySecretsManagerClient);

        // Then
        expect(spySecretsManagerClient.send.calledWith(sinon.match.instanceOf(GetSecretValueCommand))).toBeTruthy()
        const argsCalledWithSpy = spySecretsManagerClient.send.firstCall.args[0].input;
        expect(argsCalledWithSpy.SecretId).toEqual(fakeSecretARN);
        // Restore the environment variable
        mockedEnvVar.restore();
    });
});

describe('getSlackSecret', () => {
    /**
     * Given a mocked SecretsManagerClient instance
     * When `getSlackSecret()` is called
     * Then it should return the parsed JSON secret
     */
    test('Gets and parses the Slack secret from SecretsManager', async () => {
        // Given
        const mockedResponse = {SecretString: '{"slack_token": "test-token"}'};
        const mockedSecretsManagerClient = {
            send: sinon.stub().resolves(mockedResponse),
        }

        // When
        const result = await index.getSlackSecret(mockedSecretsManagerClient);

        // Then
        expect(result).toEqual({slack_token: 'test-token'});
    });
});

describe('listFiles', () => {
    /**
     * Given an S3 bucket name and prefix to filter files b
     * When `listFiles()` is called
     * Then the correct command is used when
     *  the `send` method is called from the `S3Client`
     */
    test('Lists files in S3 bucket with the specified prefix', async () => {
        // Given
        const bucketName = 'test-bucket'
        const prefix = 'test-prefix'
        const spyS3Client = {
            send: sinon.stub().resolves({}),
        }

        // When
        await index.listFiles(bucketName, prefix, spyS3Client);

        // Then
        expect(spyS3Client.send.calledWith(sinon.match.instanceOf(ListObjectsV2Command))).toBeTruthy()
        const argsCalledWithSpy = spyS3Client.send.firstCall.args[0].input;
        expect(argsCalledWithSpy.Bucket).toEqual(bucketName);
        expect(argsCalledWithSpy.Prefix).toEqual(prefix);
    });
});

describe('streamToBuffer', () => {
    /**
     * Given a stream
     * When `streamToBuffer()` is called
     * Then it should return the buffer created from the stream data
     */
    test('Converts a stream to a buffer', async () => {
        // Given
        const mockStream = {
            on: jest.fn((event, callback) => {
                if (event === 'data') callback(Buffer.from('chunk'));
                if (event === 'end') callback();
            }),
        };

        // When
        const result = await index.streamToBuffer(mockStream);

        // Then
        expect(result).toEqual(Buffer.from('chunk'));
    });
});

describe('downloadFile', () => {
    /**
     * Given an S3 bucket and key
     * When `downloadFile()` is called
     * Then it should return the file from S3
     */
    test('Downloads the file from S3', async () => {
        // Given
        const bucketName = 'test-bucket'
        const key = 'test-key'
        const mockedResponse = {Body: 'fileContent'};
        const spyS3Client = {
            send: sinon.stub().resolves(mockedResponse),
        }

        // When
        const result = await index.downloadFile(bucketName, key, spyS3Client);

        // Then
        expect(spyS3Client.send.calledWith(sinon.match.instanceOf(GetObjectCommand))).toBeTruthy()
        const argsCalledWithSpy = spyS3Client.send.firstCall.args[0].input;
        expect(argsCalledWithSpy.Bucket).toEqual(bucketName);
        expect(argsCalledWithSpy.Key).toEqual(key);
        expect(result).toBe(mockedResponse);
    });
});

describe('downloadAllFiles', () => {
    /**
     * Given an S3 bucket and multiple keys
     * When `downloadAllFiles()` is called
     * Then it should return all the files from S3
     */
    test('Downloads all files from S3', async () => {
        // Given
        const keys = ['key1', 'key2']
        const bucketName = 'test-bucket'
        const mockedResponse = {Body: 'fileContent'};
        const spyS3Client = {
            send: sinon.stub().resolves(mockedResponse),
        }

        // When
        const result = await index.downloadAllFiles(keys, bucketName, spyS3Client);

        // Then
        expect(result).toEqual([{key: 'key1', content: mockedResponse}, {key: 'key2', content: mockedResponse},]);
        expect(spyS3Client.send.calledTwice).toBeTruthy();
    });
});

describe('getFileUploadURLToSlack', () => {
    /**
     * Given a `WebClient`, filename, and length
     * When `getFileUploadURLToSlack()` is called
     * Then it should call `getUploadURLExternal` on the client with correct arguments
     */
    test('Calls `getUploadURLExternal` with correct arguments and returns result', async () => {
        // Given
        const mockedSlackClient = {
            files: {
                getUploadURLExternal: sinon.stub(),
            }, token: 'fake-token',
        };
        const filename = '01-covid-19-failed.png';
        const length = 1024;
        const mockResponse = {upload_url: 'https://slack.com/upload', file_id: 'abc123'};
        mockedSlackClient.files.getUploadURLExternal.resolves(mockResponse);

        // When
        const result = await index.getFileUploadURLToSlack(mockedSlackClient, filename, length);

        // Then
        sinon.assert.calledOnceWithExactly(mockedSlackClient.files.getUploadURLExternal, {
            token: mockedSlackClient.token, filename: filename, length: length,
        });
        expect(result).toEqual(mockResponse);
    });
});

describe('sendPostRequest', () => {
    /**
     * Given a URL, filename, and file buffer stream
     * When `sendPostRequest()` is called
     * Then it should send a POST request with the file
     */
    test('Sends a POST request to the given URL', async () => {
        // Given
        const fakeURL = 'https://slack.com/upload';
        const fakeFilename = '01-covid-19-failed.png';
        const fakeFileBufferStream = Buffer.from('fileContent');
        axios.post.mockResolvedValue({status: 200});

        // When
        await index.sendPostRequest(fakeURL, fakeFilename, fakeFileBufferStream);

        // Then
        expect(axios.post).toHaveBeenCalledWith(fakeURL, expect.any(FormData), {
            headers: expect.any(Object),
        });
    });
});

describe('completeFileUploadToSlack', () => {
    /**
     * Given a mocked `WebClient`, file details, channel ID, and thread timestamp
     * When `completeFileUploadToSlack()` is called
     * Then it should call `completeUploadExternal` on the Slack client with correct arguments
     */
    test('Completes a file upload in Slack', async () => {
        // Given
        const mockSlackClient = {
            files: {
                completeUploadExternal: sinon.stub().resolves()
            }, token: 'fake-token',
        };
        const files = [{id: 'file_id', title: 'file.txt'}];
        const channelId = 'C123';
        const threadTs = 'thread_ts';

        // When
        await index.completeFileUploadToSlack(mockSlackClient, files, channelId, threadTs);

        // Then
        sinon.assert.calledOnceWithExactly(mockSlackClient.files.completeUploadExternal, {
            token: mockSlackClient.token, files: files, channel_id: channelId, thread_ts: threadTs,
        });
    });
});

describe('getDirectoryPath', () => {
    /**
     * Given a full file path
     * When `getDirectoryPath()` is called
     * Then the directory path is returned
     */
    test('Returns the directory path for the prefix', () => {
        // Given
        const prefix = 'canary/eu-west-2/test-env-display/2024/08/08/15-02-01';
        const filePath = `${prefix}/01-covid-19-failed.png`

        // When
        const result = index.getDirectoryPath(filePath);

        // Then
        expect(result).toBe(prefix);
    });
});

describe('getCurrentDate', () => {
    /**
     * Given no input
     * When `getCurrentDate()` is called
     * Then it should return the current date in YYYY/MM/DD format
     */
    test('Returns the current date in YYYY/MM/DD format', () => {
        // Given
        // Date is mocked to avoid any potential flakiness
        const frozenDate = new Date('2023-12-25T00:00:00Z');
        jest.spyOn(global, 'Date').mockImplementation(() => frozenDate);

        // When
        const result = index.getCurrentDate();

        // Then
        const expectedDate = {
            'year': '2023', 'month': '12', 'day': '25', 'hour': '00'
        }
        expect(result).toStrictEqual(expectedDate);
    });
});

describe('extractFailedScreenshotKeys', () => {
    /**
     * Given an S3 file list
     * When `extractFailedScreenshotKeys()` is called
     * Then it should return the keys of failed screenshots
     */
    test('Extracts keys of failed screenshots from S3 file list', () => {
        // Given
        const failedKey = 'canary/eu-west-2/test-env-display/2024/08/08/15-02-01/01-covid-19-failed.png'
        const succeededKey = 'canary/eu-west-2/test-env-display/2024/08/08/15-02-01/02-influenza-succeeded.png'
        const fakeKeys = [{Key: failedKey}, {Key: succeededKey},];

        // When
        const result = index.extractFailedScreenshotKeys(fakeKeys);

        // Then
        expect(result).toEqual([failedKey]);
    });
});

describe('extractReportKey', () => {
    /**
     * Given an S3 file list
     * When `extractReportKey()` is called
     * Then it should return the key of the report
     */
    test('Extracts the report key from S3 file list', () => {
        // Given
        const failedScreenshotKey = 'canary/eu-west-2/test-env-display/2024/08/08/15-02-01/01-covid-19-failed.png'
        const BrokenKeyLinksReportKey = 'canary/eu-west-2/test-env-display/2024/08/08/15-02-01/BrokenLinkCheckerReport.json'
        const fakeKeys = [{Key: failedScreenshotKey}, {Key: BrokenKeyLinksReportKey},];
        const keyToSearchFor = 'BrokenLinkCheckerReport'

        // When
        const result = index.extractReportKey(fakeKeys, keyToSearchFor);

        // Then
        expect(result).toBe(BrokenKeyLinksReportKey);
    });
});

describe('buildSlackPostPayload', () => {
    /**
     * Given a target, timestamps and an array of broken links
     * When `buildSlackPostPayload()` is called
     * Then it should return the payload for posting to Slack
     */
    test('Builds the Slack post payload', () => {
        // Given
        const target = 'uhd-test-env-display'
        const startTime = 'fake-start-time'
        const endTime = 'fake-end-time'
        const brokenLinks = ['fake-link-1.com', 'fake-link-2.com']

        // When
        const result = index.buildSlackPostPayload(target, startTime, endTime, brokenLinks);

        // Then
        const expectedPayload = [{
            "type": "header", "text": {
                "type": "plain_text", "text": ":alert: Canary run failed", "emoji": true
            }
        }, {
            "type": "divider"
        }, {
            "type": "section", "text": {
                "type": "mrkdwn", "text": `*Alarm name:*\n${target}`
            }
        }, {
            "elements": [{
                "elements": [{
                    "text": "Detected broken link(s):\n", "type": "text"
                }], "type": "rich_text_section"
            }, {
                "border": 0, "elements": [{
                    "elements": [{
                        "type": "link", "url": "fake-link-1.com"
                    }], "type": "rich_text_section"
                }, {
                    "elements": [{
                        "type": "link", "url": "fake-link-2.com"
                    }], "type": "rich_text_section"
                }], "indent": 0, "style": "bullet", "type": "rich_text_list"
            }], "type": "rich_text"
        }, {
            "type": "context", "elements": [{
                "type": "plain_text", "text": `Canary started at ${startTime} and failed at ${endTime}`
            }]
        },]
        expect(result).toEqual(expectedPayload);
    });
});

describe('uploadScreenshotToSlackThread', () => {
    /**
     * Given a Slack channel ID and thread ts value
     * When `uploadScreenshotToSlackThread()` is called
     * Then the call is delegated to the relevant functions
     */
    it('should correctly upload a screenshot to a Slack thread', async () => {
        // Given
        const mockedSlackClient = sinon.stub();
        const fakeDownloadedFileResponse = {content: {Body: 'fake-body'}, key: 'fake-key'};
        const fakeChannelId = 'C123';
        const fakeThreadTs = 'fake_thread_ts_value';
        const fileBufferStream = Buffer.from('mock-buffer');
        const fakeFileName = 'fake-screenshot.png';
        const fakeFileUploadURLResponse = {upload_url: 'https://slack.com/upload', file_id: 'fake-file-id'};

        const spyStreamToBuffer = sinon.stub().resolves(fileBufferStream);
        const spyGetFilename = sinon.stub().returns(fakeFileName);
        const spyGetFileUploadURLToSlack = sinon.stub().resolves(fakeFileUploadURLResponse);
        const spySendPostRequest = sinon.stub();
        const spyCompleteFileUploadToSlack = sinon.stub();
        const overriddenDependencies = {
            streamToBuffer: spyStreamToBuffer,
            getFilename: spyGetFilename,
            getFileUploadURLToSlack: spyGetFileUploadURLToSlack,
            sendPostRequest: spySendPostRequest,
            completeFileUploadToSlack: spyCompleteFileUploadToSlack
        };

        // When
        await index.uploadScreenshotToSlackThread(
            fakeDownloadedFileResponse,
            mockedSlackClient,
            fakeChannelId,
            fakeThreadTs,
            overriddenDependencies
        );

        // Then
        expect(spyStreamToBuffer.calledOnceWithExactly(fakeDownloadedFileResponse.content.Body)).toBeTruthy();
        expect(spyGetFilename.calledOnceWithExactly(fakeDownloadedFileResponse.key)).toBeTruthy();
        expect(spyGetFileUploadURLToSlack.calledOnceWithExactly(mockedSlackClient, fakeFileName, fileBufferStream.length)).toBeTruthy();
        expect(spySendPostRequest.calledOnceWithExactly(fakeFileUploadURLResponse.upload_url, fakeFileName, fileBufferStream)).toBeTruthy();
        const expectedFiles = [{id: fakeFileUploadURLResponse.file_id, title: fakeFileName}];
        expect(spyCompleteFileUploadToSlack.calledOnceWithExactly(mockedSlackClient, expectedFiles, fakeChannelId, fakeThreadTs)).toBeTruthy();

        sinon.restore()
    });

});

describe('uploadAllScreenshotsToSlackThread', () => {
    /**
     * Given a Slack client, files array, channel, and threadTs
     * When `uploadAllScreenshotsToSlackThread()` is called
     * Then the call is delegated to `uploadScreenshotToSlackThread()`
     */
    test('Uploads all screenshots to a Slack thread', async () => {
        // Given
        const mockedSlackClient = sinon.stub();
        const spyUploadScreenshotToSlackThread = sinon.stub()
        const fakeDownloadResponses = [
            {content: {Body: 'fake-body-1'}, key: 'fake-key-2'},
            {content: {Body: 'fake-body-1'}, key: 'fake-key-2'},
        ]
        const overriddenDependencies = {
            uploadScreenshotToSlackThread: spyUploadScreenshotToSlackThread,
        };
        const fakeChannelID = 'fake-channel-id';
        const fakeThreadTsValue = 'fake-thread-ts-value';

        // When
        await index.uploadAllScreenshotsToSlackThread(
            fakeDownloadResponses,
            mockedSlackClient,
            fakeChannelID,
            fakeThreadTsValue,
            overriddenDependencies
        );

        // Then
        expect(spyUploadScreenshotToSlackThread.calledTwice).toBeTruthy()
        const expectedArgs = [
            [fakeDownloadResponses[0], mockedSlackClient, fakeChannelID, fakeThreadTsValue],
            [fakeDownloadResponses[1], mockedSlackClient, fakeChannelID, fakeThreadTsValue],
        ]
        expect(spyUploadScreenshotToSlackThread.args).toStrictEqual(expectedArgs)

    });
});

describe('sendSlackPost', () => {
    /**
     * Given a Slack client, payload, and channelId
     * When `sendSlackPost()` is called
     * Then it should send a post request to the Slack API
     */
    test('Sends a post request to the Slack API', async () => {
        // Given
        const mockedSlackClient = {
            chat: {
                postMessage: sinon.stub(),
            }, token: 'fake-token',
        };
        const fakeChannelId = 'C123'
        const payload = {text: 'Test', channel: fakeChannelId};

        // When
        const result = await index.sendSlackPost(mockedSlackClient, payload, fakeChannelId);

        // Then
        sinon.assert.calledOnceWithExactly(mockedSlackClient.chat.postMessage, {
            token: mockedSlackClient.token,
            channel: fakeChannelId,
            blocks: payload,
            text: 'Synthetic monitoring alert raised'
        });
    });
});


describe('getPreviousCanaryRun', () => {
    /**
     * Given the name of the synthetics canary
     * When `getPreviousCanaryRun()` is called
     * Then the correct command is used when
     *  the `send` method is called from the `SyntheticsClient`
     */
    test('Gets the recent canary run from Synthetics', async () => {
        // Given
        const fakeCanaryName = 'fake-canary-name'
        const spySyntheticsClient = {
            send: sinon.stub().resolves({}),
        }

        // When
        await index.getPreviousCanaryRun(fakeCanaryName, spySyntheticsClient);

        // Then
        expect(spySyntheticsClient.send.calledWith(sinon.match.instanceOf(GetCanaryRunsCommand))).toBeTruthy()
        const argsCalledWithSpy = spySyntheticsClient.send.firstCall.args[0].input;
        expect(argsCalledWithSpy.Name).toEqual(fakeCanaryName);
        expect(argsCalledWithSpy.MaxResults).toEqual(1);
    });
})

describe('getRunStateOfPreviousRun', () => {
    /**
     * Given the recent canary runs
     * When `getRunStateOfPreviousRun()` is called
     * Then the correct state is returned
     */
    test('Extracts the state associated with the most recent canary run', async () => {
        // Given
        const recentRuns = {
            "CanaryRuns": [
                {
                    "Name": "uhd-fake-env-display",
                    "Status": {
                        "State": "FAILED",
                        "StateReason": "",
                        "StateReasonCode": ""
                    },
                }
            ],
        }

        // When
        const extractedStatus = index.getRunStateOfPreviousRun(recentRuns);

        // Then
        expect(extractedStatus).toStrictEqual("FAILED")
    });
})

describe('determineIfNotificationIsRequired', () => {
    const failedEvent = {
        "detail-type": "Synthetics Canary TestRun Failure",
        "source": "aws.synthetics",
        "account": "123456789012",
        "detail": {
            "account-id": "123456789012",
            "test-run-status": "FAILED",
        }
    };
    const passedEvent = {
        "detail-type": "Synthetics Canary TestRun Failure",
        "source": "aws.synthetics",
        "account": "123456789012",
        "detail": {
            "account-id": "123456789012",
            "test-run-status": "PASSED",
        }
    };

    test.each([
        {
            description: 'Returns true when run changed from PASSED to FAILED',
            event: failedEvent,
            previousRunStatus: 'PASSED',
            expectedResult: true
        },
        {
            description: 'Returns false when run remained as FAILED between runs',
            event: failedEvent,
            previousRunStatus: 'FAILED',
            expectedResult: false
        },
        {
            description: 'Returns false when run changed from FAILED to PASSED',
            event: passedEvent,
            previousRunStatus: 'FAILED',
            expectedResult: false
        },
        {
            description: 'Returns false when run changed from PASSED to PASSED',
            event: passedEvent,
            previousRunStatus: 'PASSED',
            expectedResult: false
        }
    ])('$description', async ({event, previousRunStatus, expectedResult}) => {
        // Given
        const mockedGetPreviousCanaryRun = sinon.stub();
        const mockedGetRunStateOfPreviousRun = sinon.stub().returns(previousRunStatus);
        const injectedDependencies = {
            getPreviousCanaryRun: mockedGetPreviousCanaryRun,
            getRunStateOfPreviousRun: mockedGetRunStateOfPreviousRun
        };

        // When
        const extractedBoolean = await index.determineIfNotificationRequired(event, injectedDependencies);

        // Then
        expect(extractedBoolean).toBe(expectedResult);
    });
});

describe('extractReport', () => {
    /**
     * Given a report key and an S3 client
     * When `extractReport()` is called
     * Then it should return the report content
     */
    test('Extracts the report content from S3', async () => {
        // Given
        const fakeS3BucketName = 'fake-s3-bucket-name-value';
        const failedScreenshotKey = 'canary/eu-west-2/test-env-display/2024/08/08/15-02-01/01-covid-19-failed.png'
        const BrokenKeyLinksReportKey = 'canary/eu-west-2/test-env-display/2024/08/08/15-02-01/BrokenLinkCheckerReport.json'
        const folderContents = [{Key: failedScreenshotKey}, {Key: BrokenKeyLinksReportKey},];
        const keyToSearchFor = 'BrokenLinkCheckerReport'

        const spyExtractReportKey = sinon.stub().returns(BrokenKeyLinksReportKey);
        const spyDownloadFile = sinon.stub().returns({Body: 'fake-stream'});
        const spyStreamToBuffer = sinon.stub().resolves(Buffer.from('{}', 'utf8'));
        const mockedS3Client = sinon.stub()
        const overriddenDependencies = {
            extractReportKey: spyExtractReportKey,
            downloadFile: spyDownloadFile,
            streamToBuffer: spyStreamToBuffer,
        };

        // When
        const result = await index.extractReport(folderContents, keyToSearchFor, fakeS3BucketName, mockedS3Client, overriddenDependencies);

        // Then
        expect(spyExtractReportKey.calledOnceWithExactly(folderContents, keyToSearchFor)).toBeTruthy();
        expect(spyDownloadFile.calledOnceWithExactly(fakeS3BucketName, BrokenKeyLinksReportKey, mockedS3Client)).toBeTruthy();
        expect(spyStreamToBuffer.calledOnceWithExactly('fake-stream')).toBeTruthy();

        sinon.restore()
    });
});

describe('handler', () => {
    let spyDetermineIfNotificationRequired
    let spyGetSlackSecret;
    let spyBuildSlackClient;
    let spyListFiles;
    let spyExtractReport;
    let spyBuildSlackPostPayload;
    let spySendSlackPost;
    let spyExtractFailedScreenshotKeys;
    let spyDownloadAllFiles;
    let spyUploadAllScreenshotsToSlackThread;
    let injectedDependencies;

    const previousRun = {
        "CanaryRuns": [
            {
                "ArtifactS3Location": "uhd-fake-env-canary-logs/canary/eu-west-2/uhd-fake-env-display/2024/08/19/14/05-39-555",
                "Name": "uhd-fake-env-display",
                "Status": {
                    "State": "PASSED",
                    "StateReason": "",
                    "StateReasonCode": ""
                },
                "Timeline": {
                    "Completed": "2024-08-19T14:10:28.342Z",
                    "Started": "2024-08-19T14:05:39.555Z"
                }
            }
        ],
        "NextToken": "2024-08-19T14:05:39.555Z"
    }

    const event = {
        "detail-type": "Synthetics Canary TestRun Successful",
        "source": "aws.synthetics",
        "time": "2024-08-19T08:35:40Z",
        "region": "eu-west-2",
        "resources": [],
        "detail": {
            "canary-name": "uhd-fake-env-display",
            "artifact-location": "uhd-fake-env-canary-logs/canary/eu-west-2/uhd-fake-env-display/2024/08/19/08/32-09-739",
            "test-run-status": "PASSED",
            "state-reason": "null",
            "canary-run-timeline": {
                "started": 1724056329.74,
                "completed": 1724056539.871
            },
            "message": "Test run result is generated successfully"
        }
    };
    const slackSecret = {slack_token: 'test-token', slack_channel_id: 'channel-id'};
    const slackClient = {someClientProperty: 'value'};
    const listedFiles = {Contents: ['file1', 'file2']};
    const syntheticsReport = {canaryName: 'Test Canary', startTime: 'start-time', endTime: 'end-time'};
    const brokenLinksReport = {brokenLinks: ['link1', 'link2']};
    const slackPayload = {text: 'payload'};
    const slackPostResponse = {ts: 'timestamp'};
    const extractedSnapshotKeys = ['key1', 'key2'];
    const downloadResponses = ['response1', 'response2'];

    beforeEach(() => {
        spyDetermineIfNotificationRequired = sinon.stub().resolves(true)
        spyGetSlackSecret = sinon.stub().resolves(slackSecret);
        spyBuildSlackClient = sinon.stub().resolves(slackClient);
        spyListFiles = sinon.stub().resolves(listedFiles);
        spyExtractReport = sinon.stub();
        spyExtractReport.withArgs(listedFiles.Contents, 'SyntheticsReport').resolves(syntheticsReport);
        spyExtractReport.withArgs(listedFiles.Contents, 'BrokenLinkCheckerReport').resolves(brokenLinksReport);
        spyBuildSlackPostPayload = sinon.stub().returns(slackPayload);
        spySendSlackPost = sinon.stub().resolves(slackPostResponse);
        spyExtractFailedScreenshotKeys = sinon.stub().returns(extractedSnapshotKeys);
        spyDownloadAllFiles = sinon.stub().resolves(downloadResponses);
        spyUploadAllScreenshotsToSlackThread = sinon.stub().resolves();

        injectedDependencies = {
            determineIfNotificationRequired: spyDetermineIfNotificationRequired,
            getSlackSecret: spyGetSlackSecret,
            buildSlackClient: spyBuildSlackClient,
            listFiles: spyListFiles,
            extractReport: spyExtractReport,
            buildSlackPostPayload: spyBuildSlackPostPayload,
            sendSlackPost: spySendSlackPost,
            extractFailedScreenshotKeys: spyExtractFailedScreenshotKeys,
            downloadAllFiles: spyDownloadAllFiles,
            uploadAllScreenshotsToSlackThread: spyUploadAllScreenshotsToSlackThread
        };
    });

    afterEach(() => {
        sinon.restore();
    });

    /**
     * Given an event object and an S3 bucket name
     * When `handler()` is called
     * Then a `WebClient` is created with the correct secret token
     */
    test('should create a `WebClient` for Slack with the token pulled from `SecretsManager`', async () => {
        // Given
        const fakeSlackToken = 'some-fake-slack-auth-token';
        spyGetSlackSecret.returns({slack_token: fakeSlackToken});

        // When
        await index.handler(event, sinon.stub(), injectedDependencies);

        // Then
        expect(spyGetSlackSecret.calledOnce).toBeTruthy()
        expect(spyBuildSlackClient.calledOnceWithExactly(fakeSlackToken)).toBeTruthy()
    });

    /**
     * Given an event object and an S3 bucket name
     * When `handler()` is called
     * Then the target folder in the S3 bucket is found and listed
     */
    test('should extract the relevant folder contents', async () => {
        // Given
        const relevantFolder = 'canary/eu-west-2/uhd-fake-env-display/2024/08/19/08/32-09-739'
        const fakeBucketName = 'fake-bucket-name-value'
        const mockedEnvVar = sinon.stub(process, 'env').value({S3_CANARY_LOGS_BUCKET_NAME: fakeBucketName});

        // When
        await index.handler(event, sinon.stub(), injectedDependencies);

        // Then
        expect(spyListFiles.calledOnceWithExactly(fakeBucketName, relevantFolder)).toBeTruthy()
        mockedEnvVar.restore();
    });

    /**
     * Given an event object and an S3 bucket name
     * When `handler()` is called
     * Then the reports and failed screenshots
     *  are pulled from the target folder in the S3 bucket
     */
    test('should extract the relevant reports and failed screenshots', async () => {
        // Given
        const failedScreenshotKey = 'canary/eu-west-2/test-env-display/2024/08/08/15-02-01/01-covid-19-failed.png'
        const BrokenKeyLinksReportKey = 'canary/eu-west-2/test-env-display/2024/08/08/15-02-01/BrokenLinkCheckerReport.json'
        const folderContents = [{Key: failedScreenshotKey}, {Key: BrokenKeyLinksReportKey},];
        spyListFiles.returns({Contents: folderContents})
        spyExtractReport.returns({canaryName: "abc", startTime: "def", endTime: "xyz", brokenLinks: []})
        const fakeBucketName = 'fake-bucket-name-value'
        const mockedEnvVar = sinon.stub(process, 'env').value({S3_CANARY_LOGS_BUCKET_NAME: fakeBucketName});

        // When
        await index.handler(event, sinon.stub(), injectedDependencies);

        // Then
        expect(spyExtractReport.calledTwice).toBeTruthy()
        const expectedArgs = [
            [folderContents, 'SyntheticsReport', fakeBucketName],
            [folderContents, 'BrokenLinkCheckerReport', fakeBucketName],
        ]
        expect(spyExtractReport.args).toStrictEqual(expectedArgs)
        mockedEnvVar.restore();
    });

    /**
     * Given an event object and an S3 bucket name
     * When `handler()` is called
     * Then a post is sent to the Slack channel
     */
    test('should post the primary message to Slack', async () => {
        // Given
        const infoExtractedFromReports = {canaryName: "abc", startTime: "def", endTime: "xyz", brokenLinks: []}
        spyExtractReport.returns(infoExtractedFromReports)
        const fakeSlackPayload = {blocks: []}
        spyBuildSlackPostPayload.returns(fakeSlackPayload)
        const fakeSlackChannelId = 'some-fake-slack-channel-id';
        spyGetSlackSecret.returns({slack_channel_id: fakeSlackChannelId});

        // When
        await index.handler(event, sinon.stub(), injectedDependencies);

        // Then
        expect(spyBuildSlackPostPayload.calledOnceWithExactly(infoExtractedFromReports))
        expect(spySendSlackPost.calledOnceWithExactly(slackClient, fakeSlackPayload, fakeSlackChannelId))
    });

    /**
     * Given an event object and an S3 bucket name
     * When `handler()` is called
     * Then the failed screenshots are uploaded
     *  to the primary post which was sent to the Slack channel
     */
    test('should get the failed screenshots and upload them to Slack', async () => {
        // Given
        const mockedFolderContents = sinon.stub()
        const bucketName = 'fake-bucket-name-value'
        spyListFiles.returns({Contents: mockedFolderContents})
        const extractedSnapshotKeys = ["abc-failed.png", "xyz-failed.png"]
        const infoExtractedFromReports = {canaryName: "abc", startTime: "def", endTime: "xyz", brokenLinks: []}
        spyExtractReport.returns(infoExtractedFromReports)

        const fakeSlackChannelId = 'some-fake-slack-channel-id';
        spyGetSlackSecret.returns({slack_channel_id: fakeSlackChannelId});

        const slackPostResponse = {
            'ts': 'abc'
        }
        spySendSlackPost.returns(slackPostResponse)

        // When
        await index.handler(event, bucketName, injectedDependencies);

        // Then
        expect(spyExtractFailedScreenshotKeys.calledOnceWithExactly(mockedFolderContents))
        expect(spyDownloadAllFiles.calledOnceWithExactly(extractedSnapshotKeys, bucketName))
        expect(spyUploadAllScreenshotsToSlackThread.calledOnceWithExactly(
            spyDownloadAllFiles.result,
            spyBuildSlackClient.result,
            fakeSlackChannelId,
            slackPostResponse.ts
        ))

    });

});
const {
    extractBucketAndObjectKey,
    downloadFileFromS3,
    constructPayload,
    calculateJitteredBackoffPeriod,
    writeDataToKinesis,
    writeDataToKinesisWithRetry,
    handler
} = require('./index.js')
const {GetObjectCommand} = require("@aws-sdk/client-s3");
const {PutRecordCommand} = require("@aws-sdk/client-kinesis");
const sinon = require('sinon');
const uuid = require('uuid');


const fakeFileContents = {
    'parent_theme': 'infectious_disease',
    'child_theme': 'respiratory',
    'topic': 'COVID-19',
    'metric_group': 'cases',
    'metric': 'COVID-19_cases_rateRollingMean',
    'geography_type': 'Nation',
    'geography': 'England',
    'geography_code': 'E92000001',
    'age': '40-44',
    'sex': 'all',
    'stratum': 'default',
    'metric_frequency': 'daily',
    'time_series': [{'epiweek': 45, 'date': '2022-11-08', 'metric_value': 136.62, 'embargo': null}],
    'refresh_date': '2023-11-09'
}
const fakeObjectKey = "in/COVID-19_cases_rateRollingMean_CTRY_E92000001_40-44_all_default.json"
const fakeBucket = "fake-test-ingest-bucket"
const fakeEvent = {
    "Records": [{
        "s3": {
            "bucket": {"name": fakeBucket}, "object": {"key": fakeObjectKey}
        }
    }]
}

describe('downloadFileFromS3', () => {
    /**
     * Given a bucket name and an object key for a given file
     * When `downloadFileFromS3()` is called
     * Then the expected file contents are returned
     */
    test('Should return the file contents when called', async () => {
        // Given
        const bucket = fakeBucket;
        const key = fakeObjectKey;
        const downloadedFileContents = fakeFileContents
        const responseBody = JSON.stringify(downloadedFileContents)

        const s3ClientStub = {
            send: sinon.stub().resolves({
                Body: {transformToString: sinon.stub().resolves(responseBody)}
            }),
        }

        // When
        const result = await downloadFileFromS3(bucket, key, s3ClientStub);

        // Then
        expect(result).toEqual(downloadedFileContents)
    });

    /**
     * Given a bucket name and an object key for a given file
     * When `downloadFileFromS3()` is called
     * Then the correct command is used when
     *  the `send` method is called from the `S3Client`
     */
    test('Calls the s3 client with the correct command object', async () => {
        // Given
        const bucket = fakeBucket;
        const key = fakeObjectKey;

        const s3ClientSpy = {
            send: sinon.stub().resolves({
                Body: {transformToString: sinon.stub().resolves(JSON.stringify(fakeFileContents))}
            }),
        }

        // When
        await downloadFileFromS3(bucket, key, s3ClientSpy);

        // Then
        // The `send()` method should only be called once
        expect(s3ClientSpy.send.calledOnce).toBeTruthy();

        // The `GetObjectCommand` should have been passed to the call to the `send()` method
        expect(s3ClientSpy.send.calledWith(sinon.match.instanceOf(GetObjectCommand))).toBeTruthy();
        const argsCalledWithSpy = s3ClientSpy.send.firstCall.args[0].input;
        expect(argsCalledWithSpy.Bucket).toEqual(bucket)
        expect(argsCalledWithSpy.Key).toEqual(key)
    });
});


describe('writeDataToKinesis', () => {
    /**
     * Given a payload and an environment variable for the Kinesis data stream name
     * When `writeDataToKinesis()` is called
     * Then the correct command is used when
     *  the `send` method is called from the `KinesisClient`
     */
    test('Calls the kinesis client with the correct command object', async () => {
        // Given
        const payload = 'fake-payload'
        const fakeKinesisDataStreamName = 'fake-kinesis-data-stream-name'
        const mockedEnvVar = sinon.stub(process, 'env').value({KINESIS_DATA_STREAM_NAME: fakeKinesisDataStreamName});
        const kinesisClientSpy = {
            send: sinon.stub().resolves({}),
        };

        // When
        await writeDataToKinesis(payload, kinesisClientSpy);

        // Then
        // The `send()` method should only be called once
        expect(kinesisClientSpy.send.calledOnce).toBeTruthy()

        // The `PutRecordCommand` should have been passed to the call to the `send()` method
        expect(kinesisClientSpy.send.calledWith(sinon.match.instanceOf(PutRecordCommand))).toBeTruthy();
        const argsCalledWithSpy = kinesisClientSpy.send.firstCall.args[0].input;
        expect(argsCalledWithSpy.StreamName).toEqual(fakeKinesisDataStreamName);
        expect(argsCalledWithSpy.Data).toEqual(Buffer.from(payload));
        expect(uuid.validate(argsCalledWithSpy.PartitionKey)).toBeTruthy();

        // Restore the environment variable
        mockedEnvVar.restore();
    });
});


describe('extractBucketAndObjectKey', () => {
    /**
     * Given an incoming event object containing the S3 bucket name and an object key
     * When `extractBucketAndObjectKey()` is called
     * Then the S3 bucket name and object key are both extracted
     */
    test('Bucket name and object key should be extracted from event', () => {
        // Given
        const bucketName = fakeBucket
        const objectKey = fakeObjectKey
        const fakeEvent = {
            "Records": [{
                "s3": {
                    "bucket": {"name": bucketName}, "object": {"key": objectKey}
                }
            }]
        }

        // When
        const {bucket, key} = extractBucketAndObjectKey(fakeEvent)

        // Then
        expect(key).toEqual(objectKey)
        expect(bucket).toEqual(bucketName)
    });

    /**
     * Given an incoming event object containing an object key with special characters
     * When `extractBucketAndObjectKey()` is called
     * Then the returned object key has been decoded
     */
    test('Object key with special character is URL decoded when returned', () => {
        // Given
        const encodedObjectKey = 'in/COVID-19_cases_rateRollingMean_CTRY_E92000001_90%2B_Male_default.json'
        const fakeEvent = {
            "Records": [{
                "s3": {
                    "bucket": {"name": fakeBucket}, "object": {"key": encodedObjectKey}
                }
            }]
        }

        // When
        const {_, key} = extractBucketAndObjectKey(fakeEvent)

        // Then
        const expectedDecodedObjectKey = 'in/COVID-19_cases_rateRollingMean_CTRY_E92000001_90+_Male_default.json'
        expect(key).toEqual(expectedDecodedObjectKey)
    });
})


describe('constructPayload', () => {
    /**
     * Given an S3 object key and the corresponding file contents object
     * When `constructPayload()` is called
     * Then the returned payload is a serialized string representation
     *   of both the key and the file contents
     */
    test('Object key and file contents are serialized to correct payload', () => {
        // Given
        const fakeKey = fakeObjectKey
        const fileContents = fakeFileContents

        // When
        const payload = constructPayload(fakeKey, fileContents)

        // Then
        const deserializePayload = JSON.parse(payload)
        expect(deserializePayload["name"]).toEqual(fakeKey)
        expect(deserializePayload["data"]).toEqual(fileContents)
    });
})


describe('calculateJitteredBackoffPeriod', () => {
    /**
     * Given a maximum delay period and a base period of 8s and 1s respectively
     * When `calculateJitterBackoffPeriod()` is called
     * Then a number between 1 and 8s is returned
     */
    test.each([
        {minPeriod: 1000, maxPeriod: 8000},
        {minPeriod: 2000, maxPeriod: 5000},
        {minPeriod: 0, maxPeriod: 10000},
        {minPeriod: 1500, maxPeriod: 7000},
        {minPeriod: 100, maxPeriod: 9000},
        {minPeriod: 3400, maxPeriod: 20000},
    ])
    ('Returns correct number between min and max allowable delay period', ({minPeriod, maxPeriod}) => {
        // Given / When
        const calculateJitterBackoffPeriod = calculateJitteredBackoffPeriod(maxPeriod, minPeriod)

        // Then
        expect(calculateJitterBackoffPeriod).toBeGreaterThanOrEqual(minPeriod)
        expect(calculateJitterBackoffPeriod).toBeLessThanOrEqual(maxPeriod)
    });
})


describe('writeDataToKinesisWithRetry', () => {
    /**
     * Given the `writeDataToKinesis()` function which returns successfully
     *   on the first attempt
     * When `writeDataToKinesisWithRetry()` is called
     * Then `writeDataToKinesis()` is called once only
     */
    test('Calls `writeDataToKinesis()` once when no errors occur', async () => {
        // Given
        const expectedConstructedPayload = JSON.stringify(fakeFileContents)

        // Injected mocked dependencies
        const writeDataToKinesisSpy = sinon.spy();
        const spyDependencies = {
            writeDataToKinesis: writeDataToKinesisSpy
        }

        // When
        await writeDataToKinesisWithRetry(expectedConstructedPayload, spyDependencies)

        // Then
        expect(writeDataToKinesisSpy.calledWith(expectedConstructedPayload)).toBeTruthy()
        sinon.assert.calledOnce(writeDataToKinesisSpy);
    })
    /**
     * Given the `writeDataToKinesis()` function which always errors
     * When `writeDataToKinesisWithRetry()` is called
     * Then `writeDataToKinesis()` is attempted 3 times
     * And the error is ultimately raised by `writeDataToKinesisWithRetry()
     */
    test('Retries `writeDataToKinesis()` 3 times when errors occur', async () => {
        // Given
        const expectedConstructedPayload = JSON.stringify(fakeFileContents)
        const expectedError = new TypeError

        // Stub out the jitter calculation so that it always returns no delay on the retry
        // otherwise a valid number between 1-8s would be calculated and applied by default
        const stubbedCalculateJitteredBackoffPeriod = sinon.stub().returns(0)

        // Injected mocked dependencies
        const writeDataToKinesisSpy = sinon.stub().throws(expectedError);
        const spyDependencies = {
            writeDataToKinesis: writeDataToKinesisSpy,
            calculateJitteredBackoffPeriod: stubbedCalculateJitteredBackoffPeriod
        }

        // When
        // The error is re-thrown when all retries have been exhausted
        await expect(writeDataToKinesisWithRetry(expectedConstructedPayload, spyDependencies)).rejects.toThrow(expectedError);

        // Then
        // Check that `writeDataToKinesis()` is retried 3 times
        expect(writeDataToKinesisSpy.callCount === 3).toBeTruthy()
    })
})

describe('handler', () => {
    /**
     * Given an S3 object key and the corresponding file contents object
     * When `constructPayload()` is called
     * Then the returned payload is a serialized string representation
     *   of both the key and the file contents
     */
    test('Orchestrates calls correctly', async () => {
        // Given
        const lambdaEvent = fakeEvent
        const expectedBucket = fakeEvent.Records[0].s3.bucket.name
        const expectedObjectKey = fakeEvent.Records[0].s3.object.key
        const expectedFileContents = fakeFileContents
        const expectedConstructedPayload = JSON.stringify(expectedFileContents)

        // Injected mocked dependencies
        const extractBucketAndObjectKeySpy = sinon.stub().returns({bucket: expectedBucket, key: expectedObjectKey});
        const downloadFileFromS3Spy = sinon.stub().resolves(expectedFileContents);
        const constructPayloadSpy = sinon.stub().returns(expectedConstructedPayload);
        const writeDataToKinesisWithRetrySpy = sinon.stub().resolves();
        const spyDependencies = {
            extractBucketAndObjectKey: extractBucketAndObjectKeySpy,
            downloadFileFromS3: downloadFileFromS3Spy,
            constructPayload: constructPayloadSpy,
            writeDataToKinesisWithRetry: writeDataToKinesisWithRetrySpy
        }

        // When
        await handler(lambdaEvent, sinon.stub(), spyDependencies)

        // Then
        expect(extractBucketAndObjectKeySpy.calledWith(lambdaEvent)).toBeTruthy()
        expect(downloadFileFromS3Spy.calledWith(expectedBucket, expectedObjectKey)).toBeTruthy()
        expect(constructPayloadSpy.calledWith(expectedObjectKey, expectedFileContents)).toBeTruthy()
        expect(writeDataToKinesisWithRetrySpy.calledWith(expectedConstructedPayload)).toBeTruthy()
    })

    /**
     * Given an S3 object key and the bucket name
     * When `constructPayload()` is called
     * Then a log statement is recorded to indicate the record was written to Kinesis
     */
    test('Records log statement once record has been written to Kinesis', async () => {
        // Given
        const lambdaEvent = fakeEvent
        const bucket = fakeEvent.Records[0].s3.bucket.name
        const key = fakeEvent.Records[0].s3.object.key

        const logSpy = jest.spyOn(console, 'log');

        // Injected stubbed dependencies
        const spyDependencies = {
            extractBucketAndObjectKey: sinon.stub().returns({bucket, key}),
            downloadFileFromS3: sinon.stub(),
            constructPayload: sinon.stub(),
            writeDataToKinesisWithRetry: sinon.stub()
        }

        // When
        await handler(lambdaEvent, sinon.stub(), spyDependencies)

        // Then
        const expectedLogStatement = `Record for '${key}' published to Kinesis`
        expect(logSpy).toHaveBeenCalledWith(expectedLogStatement);
    })

})

import json
import boto3
import os
import uuid
from urllib.parse import unquote


def handler(event, context) -> dict[str, int | str]:
    """Consumes incoming lambda events subscribing to the data stream

    Args:
        event: The lambda event provided by the AWS runtime.
            This contains the messages which are to be ingested
        context: The lambda runtime context regarding the function

    Returns:
        Dict containing information regarding the response

    Raises:
        `KeyError`: If the incoming event does not contain
            the associated records information
            in the expected structure

    """
    record: dict = event["Records"][0]["s3"]
    s3_bucket: str = record["bucket"]["name"]
    s3_object_key: str = record["object"]["key"]

    # Handle special characters in the object key name
    # as these characters get URL-encoded by S3 ahead of time
    s3_object_key: str = unquote(string=s3_object_key)

    # Download the file from the s3 bucket and extract the contents
    s3_client = boto3.client("s3")
    response = s3_client.get_object(Bucket=s3_bucket, Key=s3_object_key)
    file_contents = response["Body"].read().decode("utf-8")

    # Serialize the name/key of the file as well as the contents to a JSON string
    payload: str = json.dumps(
        {
            "name": os.path.basename(s3_object_key),
            "data": json.loads(file_contents),
        }
    )

    # Write the name/key and the data/contents of the file to the kinesis stream
    kinesis_client = boto3.client("kinesis")
    kinesis_client.put_record(
        StreamName=os.environ.get("KINESIS_DATA_STREAM_NAME"),
        Data=payload,
        PartitionKey=str(uuid.uuid4()),
    )

    log_message = f"Record for `{s3_object_key}` published to Kinesis"
    print(log_message)

    return {"statusCode": 200, "body": log_message}

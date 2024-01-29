"""
For processing data sent to Firehose by Cloudwatch Logs subscription filters.

Additional processing of message into format for Splunk HTTP Event Collector - Event input (not Raw)

Cloudwatch Logs sends to Firehose records that look like this:

{
  "messageType": "DATA_MESSAGE",
  "owner": "123456789012",
  "logGroup": "log_group_name",
  "logStream": "log_stream_name",
  "subscriptionFilters": [
    "subscription_filter_name"
  ],
  "logEvents": [
    {
      "id": "01234567890123456789012345678901234567890123456789012345",
      "timestamp": 1510109208016,
      "message": "log message 1"
    },
    {
      "id": "01234567890123456789012345678901234567890123456789012345",
      "timestamp": 1510109208017,
      "message": "log message 2"
    }
    ...
  ]
}

The data is additionally compressed with GZIP.

The code below will:

1) Gunzip the data
2) Parse the json
3) Set the result to ProcessingFailed for any record whose messageType is not DATA_MESSAGE, thus redirecting them to the
   processing error output. Such records do not contain any log events. You can modify the code to set the result to
   Dropped instead to get rid of these records completely.
4) For records whose messageType is DATA_MESSAGE, extract the individual log events from the logEvents field, and pass
   each one to the transformLogEvent method. You can modify the transformLogEvent method to perform custom
   transformations on the log events.
5) Concatenate the result from (4) together and set the result as the data of the record returned to Firehose. Note that
   this step will not add any delimiters. Delimiters should be appended by the logic within the transformLogEvent
   method.
6) Any additional records which exceed 6MB will be re-ingested back into Firehose.

"""

import base64
import json
import gzip
import boto3
import os
import sys

IS_PY3 = sys.version_info[0] == 3
if IS_PY3:
    import io
else:
    import StringIO

def transformLogEvent(log_event,acct,arn,loggrp,logstrm,filterName):
    """Transform each log event.

    This function has been customised from the default, specifically to setup indexed fields and set a more suitable sourcetype

    Args:
    log_event (dict): The original log event. Structure is {"id": str, "timestamp": long, "message": str}
    acct: The aws account from where the Cloudwatch event came from
    arn: The ARN of the Kinesis Stream
    loggrp: The Cloudwatch log group name
    logstrm: The Cloudwatch logStream name (not used below)
    filterName: The Cloudwatch Subscription filter for the Stream
    Returns:
    str: The transformed log event.
        In the case below, Splunk event details are set as:
        time = event time for the Cloudwatch Log
        host = ARN of Firehose
        source = filterName (of cloudwatch Log) contatinated with LogGroup Name
        sourcetype is set as -
            if envvar SPLUNK_SOURCETYPE is set, use that
            various other sourcetypes based on the cloudwatch loggroup name (as seen in the if/elif section below)
            otherwise use aws:cloudwatch:logs
    """

    region_name=arn.split(':')[3]
    # note that the region_name is taken from the region for the Stream, this won't change if Cloudwatch from another account/region. Not used for this example function

   # if the SPLUNK_SOURCETYPE env var is set, use that; otherwise set the sourcetype based on the loggrp name; if that doesn't work default to aws:cloudwatchlogs
    if "SPLUNK_SOURCETYPE" in os.environ:
        sourcetype=os.environ['SPLUNK_SOURCETYPE']
    elif "ec2" in loggrp: # no log Group containing "ec2" -> can me removed in the clean up
        sourcetype="aws:cloudwatchlogs:ec2" # no log Group containing "ec2" -> can me removed in the clean up
    elif "lambda/" in loggrp:
        sourcetype="aws:cloudwatchlogs:lambda"
    elif "parallelcluster/" in loggrp:
        sourcetype="aws:cloudwatchlogs:parallelcluster"
    elif "ecs/" in loggrp:
        sourcetype="aws:cloudwatchlogs:ecs"
    elif "CloudStorageSecurity." in loggrp:
        sourcetype="aws:cloudwatchlogs:CloudStorageSecurity"                 
    elif "glue-script" in loggrp:
            sourcetype="aws:cloudwatchlogs:glue-script"
    elif "glue-connection" in loggrp:
            sourcetype="aws:cloudwatchlogs:glue-connection"
    elif "/aws-glue/sessions/error" in loggrp:
            sourcetype="aws:cloudwatchlogs:glue-errors"
    elif "/aws-glue/sessions/output" in loggrp:
            sourcetype="aws:cloudwatchlogs:glue-output"         
    elif "/aws-glue/jobs/logs-v2" in loggrp:
            sourcetype="aws:cloudwatchlogs:glue-logs-v2"                    
    elif "posit-rds" in loggrp:
        sourcetype="aws:cloudwatchlogs:posit-rds"
    elif "kinesisfirehose" in loggrp:
        sourcetype="aws:cloudwatchlogs:kinesisfirehose"
    elif "stepfns" in loggrp:
        sourcetype="aws:cloudwatchlogs:stepfns"
    elif "sagemaker" in loggrp:
        sourcetype="aws:cloudwatchlogs:sagemaker"        
    elif "/aws/redshift" in loggrp:
        sourcetype="aws:cloudwatchlogs:redshift"        
    elif "/aws/containerinsights/" in loggrp:
        sourcetype="aws:cloudwatchlogs:containerinsights"             
    elif "jupyternotebook" in loggrp:
        sourcetype="aws:cloudwatchlogs:jupyternotebook"             
    elif "API-Gateway-Execution-Logs" in loggrp:
        sourcetype="aws:cloudwatchlogs:API-Gateway-Execution-Logs"   
    elif "sns/" in loggrp:
        sourcetype="aws:cloudwatchlogs:sns"   
    elif "CloudTrail" in loggrp: # no log Group containing "CloudTrail" -> can me removed in the clean up
        sourcetype="aws:cloudtrail" # no log Group containing "CloudTrail" -> can me removed in the clean up
    elif "/aws/cloudtrail" in loggrp: 
        sourcetype="aws:cloudtrail"
    elif "/aws/vpc" in loggrp:
        sourcetype="aws:cloudwatchlogs:vpcflow"
    else:
        sourcetype="aws:cloudwatchlogs"

    #build a JSON payload for the indexed fields, store AWS metadata in there:
    hec_fields = {'aws_account_id':acct, "region":region_name, "aws_log_group":loggrp}
    return_message = '{"time": ' + str(log_event['timestamp']) + ',"host": "' + arn  +'","source": "' + filterName +':' + loggrp + '"'
    return_message = return_message + ',"sourcetype":"' + sourcetype  + '"'
    return_message = return_message + ',"event": ' + json.dumps(log_event['message']) + ',"fields": ' +json.dumps(hec_fields) + '}\n'

    print("Here is the transformLogEvent function return:\n" + return_message)
    return return_message + '\n'

def processRecords(records,arn):
    for r in records:
        data = base64.b64decode(r['data'])
        if IS_PY3:
            striodata = io.BytesIO(data)
        else:
            striodata = StringIO.StringIO(data)
        with gzip.GzipFile(fileobj=striodata, mode='r') as f:
            data = json.loads(f.read())

        recId = r['recordId']
        """
        CONTROL_MESSAGE are sent by CWL to check if the subscription is reachable.
        They do not contain actual data.
        """
        if data['messageType'] == 'CONTROL_MESSAGE':
            yield {
                'result': 'Dropped',
                'recordId': recId
            }
        elif data['messageType'] == 'DATA_MESSAGE':
            data = ''.join([transformLogEvent(e,data['owner'],arn,data['logGroup'],data['logStream'],data['subscriptionFilters'][0]) for e in data['logEvents']])
            if IS_PY3:
                data = base64.b64encode(data.encode('utf-8')).decode()
            else:
                data = base64.b64encode(data)
            yield {
                'data': data,
                'result': 'Ok',
                'recordId': recId
            }
        else:
            yield {
                'result': 'ProcessingFailed',
                'recordId': recId
            }

def putRecordsToFirehoseStream(streamName, records, client, attemptsMade, maxAttempts):
    failedRecords = []
    codes = []
    errMsg = ''
    # if put_record_batch throws for whatever reason, response['xx'] will error out, adding a check for a valid
    # response will prevent this
    response = None
    try:
        response = client.put_record_batch(DeliveryStreamName=streamName, Records=records)
    except Exception as e:
        failedRecords = records
        errMsg = str(e)

    # if there are no failedRecords (put_record_batch succeeded), iterate over the response to gather results
    if not failedRecords and response and response['FailedPutCount'] > 0:
        for idx, res in enumerate(response['RequestResponses']):
            # (if the result does not have a key 'ErrorCode' OR if it does and is empty) => we do not need to re-ingest
            if 'ErrorCode' not in res or not res['ErrorCode']:
                continue

            codes.append(res['ErrorCode'])
            failedRecords.append(records[idx])

        errMsg = 'Individual error codes: ' + ','.join(codes)

    if len(failedRecords) > 0:
        if attemptsMade + 1 < maxAttempts:
            print('Some records failed while calling PutRecordBatch to Firehose stream, retrying. %s' % (errMsg))
            putRecordsToFirehoseStream(streamName, failedRecords, client, attemptsMade + 1, maxAttempts)
        else:
            raise RuntimeError('Could not put records after %s attempts. %s' % (str(maxAttempts), errMsg))

def putRecordsToKinesisStream(streamName, records, client, attemptsMade, maxAttempts):
    failedRecords = []
    codes = []
    errMsg = ''
    # if put_records throws for whatever reason, response['xx'] will error out, adding a check for a valid
    # response will prevent this
    response = None
    try:
        response = client.put_records(StreamName=streamName, Records=records)
    except Exception as e:
        failedRecords = records
        errMsg = str(e)

    # if there are no failedRecords (put_record_batch succeeded), iterate over the response to gather results
    if not failedRecords and response and response['FailedRecordCount'] > 0:
        for idx, res in enumerate(response['Records']):
            # (if the result does not have a key 'ErrorCode' OR if it does and is empty) => we do not need to re-ingest
            if 'ErrorCode' not in res or not res['ErrorCode']:
                continue

            codes.append(res['ErrorCode'])
            failedRecords.append(records[idx])

        errMsg = 'Individual error codes: ' + ','.join(codes)

    if len(failedRecords) > 0:
        if attemptsMade + 1 < maxAttempts:
            print('Some records failed while calling PutRecords to Kinesis stream, retrying. %s' % (errMsg))
            putRecordsToKinesisStream(streamName, failedRecords, client, attemptsMade + 1, maxAttempts)
        else:
            raise RuntimeError('Could not put records after %s attempts. %s' % (str(maxAttempts), errMsg))

def createReingestionRecord(isSas, originalRecord):
    if isSas:
        return {'data': base64.b64decode(originalRecord['data']), 'partitionKey': originalRecord['kinesisRecordMetadata']['partitionKey']}
    else:
        return {'data': base64.b64decode(originalRecord['data'])}

def getReingestionRecord(isSas, reIngestionRecord):
    if isSas:
        return {'Data': reIngestionRecord['data'], 'PartitionKey': reIngestionRecord['partitionKey']}
    else:
        return {'Data': reIngestionRecord['data']}

def lambda_handler(event, context):
    isSas = 'sourceKinesisStreamArn' in event
    streamARN = event['sourceKinesisStreamArn'] if isSas else event['deliveryStreamArn']
    region = streamARN.split(':')[3]
    streamName = streamARN.split('/')[1]

    records = list(processRecords(event['records'],streamARN))
    projectedSize = 0
    dataByRecordId = {rec['recordId']: createReingestionRecord(isSas, rec) for rec in event['records']}
    putRecordBatches = []
    recordsToReingest = []
    totalRecordsToBeReingested = 0

    for idx, rec in enumerate(records):
        if rec['result'] != 'Ok':
            continue
        projectedSize += len(rec['data']) + len(rec['recordId'])
        # 6000000 instead of 6291456 to leave ample headroom for the stuff we didn't account for
        if projectedSize > 6000000:
            totalRecordsToBeReingested += 1
            recordsToReingest.append(
                getReingestionRecord(isSas, dataByRecordId[rec['recordId']])
            )
            records[idx]['result'] = 'Dropped'
            del(records[idx]['data'])

        # split out the record batches into multiple groups, 500 records at max per group
        if len(recordsToReingest) == 500:
            putRecordBatches.append(recordsToReingest)
            recordsToReingest = []

    if len(recordsToReingest) > 0:
        # add the last batch
        putRecordBatches.append(recordsToReingest)

    # iterate and call putRecordBatch for each group
    recordsReingestedSoFar = 0
    if len(putRecordBatches) > 0:
        client = boto3.client('kinesis', region_name=region) if isSas else boto3.client('firehose', region_name=region)
        for recordBatch in putRecordBatches:
            if isSas:
                putRecordsToKinesisStream(streamName, recordBatch, client, attemptsMade=0, maxAttempts=20)
            else:
                putRecordsToFirehoseStream(streamName, recordBatch, client, attemptsMade=0, maxAttempts=20)
            recordsReingestedSoFar += len(recordBatch)
            print('Reingested %d/%d records out of %d' % (recordsReingestedSoFar, totalRecordsToBeReingested, len(event['records'])))
    else:
        print('No records to be reingested')

    return {"records": records}
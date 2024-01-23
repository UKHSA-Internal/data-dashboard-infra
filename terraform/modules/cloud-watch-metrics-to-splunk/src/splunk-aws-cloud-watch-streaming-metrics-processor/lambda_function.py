import base64
import copy
import json
import ast
import os
import sys

from google.protobuf.internal.decoder import _DecodeVarint
from google.protobuf.json_format import MessageToDict

from opentelemetry.proto.collector.metrics.v1.metrics_service_pb2 import ExportMetricsServiceRequest;


def lambda_handler(event, context):
	metrics = []
	for record in event['records']:
		record_data = record['data']
		base64_decoded = base64.b64decode(record_data)
		if os.environ["METRICS_OUTPUT_FORMAT"].lower() == "otel":
			metric_data = read_delimited(base64_decoded, ExportMetricsServiceRequest)
			metric_encoded_bytes = base64.b64encode(
				bytearray(
					# please note that in future AWS may send multiple ResourceMetrics in one request
					json.dumps(metric_data[0]),
					'utf-8'))
		elif os.environ["METRICS_OUTPUT_FORMAT"].lower() == "json":
			decoded_metrics = base64_decoded.decode("utf-8").splitlines()
			transformed_metric_data = transform_json_metric_event(decoded_metrics)
			metric_encoded_bytes = base64.b64encode(
				bytearray(
					# please note that in future AWS may send multiple ResourceMetrics in one request
					json.dumps(transformed_metric_data),
					'utf-8'))
		else:
			print("Invalid METRICS_OUTPUT_FORMAT value. Set to either json or otel")
			sys.exit(1)

		metric_encoded_string = str(metric_encoded_bytes, 'utf-8')
		event_map = copy.deepcopy(record)
		event_map['data'] = metric_encoded_string
		event_map['result'] = 'Ok'
		metrics.append(event_map)

	return {'records': metrics}


def transform_json_metric_event(metrics):
	'''
    Convert streaming metrics event format similar to output AWS TA metric event format
    (The conversion helps the AWS app to interpret metrics and help populating existing dashboards)
    '''
	events = []
	for metric_string in metrics:
		metric = ast.literal_eval(metric_string)
		metric_event = copy.deepcopy(metric)
		# reformat metric_dimensions
		extracted_dims = {
			'dims': ','.join([
				'{}=[{}]'.format(key, value)
				for key, value in metric_event["dimensions"].items()
			])
		}
		metric_event["metric_dimensions"] = extracted_dims["dims"]
		metric_event.pop("dimensions")
		# reformat metric values
		for k, v in metric_event["value"].items():
			if k == "count":
				metric_event["SampleCount"] = v
			if k == "sum":
				metric_event["Sum"] = v
			if k == "max":
				metric_event["Maximum"] = v
			if k == "min":
				metric_event["Minimum"] = v

		metric_event["Average"] = metric_event["Sum"] / metric_event["SampleCount"]
		metric_event.pop("value")
		# build splunk event
		# Modify sourcetype in token for aws:cloudwatch:metric if required
		if os.environ['SPLUNK_CLOUDWATCH_SOURCETYPE']:
			sourcetype = os.environ['SPLUNK_CLOUDWATCH_SOURCETYPE']
		else:
			sourcetype = "aws:cloudwatch"

		event = {"event": metric_event,
		         "source": '{}:{}'.format(metric_event["region"], metric_event["namespace"]),
		         "sourcetype": sourcetype,
		         "time": metric_event["timestamp"]}
		events.append(event)

	return events


def convert_protobuf_dict(metric):
	return MessageToDict(metric)


def read_delimited(data, metric_type):
	result = []
	start = 0
	while len(data) > 0 and start < len(data):
		(msg_length, hdr_length) = _DecodeVarint(data[start:], 0)
		# read message as a byte string
		proto_str = data[start + hdr_length:start + msg_length + hdr_length]
		# EOF
		if len(proto_str) == 0:
			return
		start = start + msg_length + hdr_length
		# de-serialize the bytes into a protobuf message
		msg = metric_type()
		msg.ParseFromString(proto_str)
		result.append(convert_protobuf_dict(msg))

	return result
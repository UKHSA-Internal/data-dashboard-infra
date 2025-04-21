module "s3_vpc_flow_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.7.0"

  bucket = "uhd-aws-vpc-flow-logs-${local.account_id}-${local.region}"

  attach_deny_insecure_transport_policy = true
  attach_policy                         = true
  force_destroy                         = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            Sid = "AWSLogDeliveryWrite",
            Effect = "Allow",
            Principal = {
                Service= "delivery.logs.amazonaws.com"
            },
            Action = "s3:PutObject",
            Resource = "arn:aws:s3:::uhd-aws-vpc-flow-logs-${local.account_id}-${local.region}/*",
            Condition = {
                StringEquals= {
                    "aws:SourceAccount" = local.account_id,
                    "s3:x-amz-acl" = "bucket-owner-full-control"
                },
                ArnLike= {
                    "aws:SourceArn"= "arn:aws:logs:region:${local.account_id}:*"
                }
            }
        },
        {
            Sid= "AWSLogDeliveryAclCheck",
            Effect= "Allow",
            Principal= {
                Service= "delivery.logs.amazonaws.com"
            },
            Action= [
                "s3:GetBucketAcl",
                "s3:ListBucket"
            ],
            Resource= "arn:aws:s3:::uhd-aws-vpc-flow-logs-${local.account_id}-${local.region}",
            Condition= {
                StringEquals= {
                    "aws:SourceAccount": local.account_id
                },
                ArnLike= {
                    "aws:SourceArn": "arn:aws:logs:region:${local.account_id}:*"
                }
            }
        }
      ]
    })
}

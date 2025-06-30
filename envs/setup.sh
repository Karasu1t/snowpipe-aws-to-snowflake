#!/bin/bash

# Create Dummy IAM Role and S3 Bucket for Snowpipe
cd aws

aws iam create-role \
  --role-name SnowflakeRole \
  --assume-role-policy-document file://trust-policy.json

aws s3api create-bucket \
  --bucket karasuit-etl-bucket \
  --region ap-northeast-1 \
  --create-bucket-configuration LocationConstraint=ap-northeast-1

# Import the resources into Terraform state
terraform import module.s3_snowpipe.aws_iam_role.snowflake_role SnowflakeRole
terraform import module.s3_snowpipe.aws_s3_bucket.etl-bucket karasuit-etl-bucket

# Terraform apply except Snowpipe

cd ../snowflake

terraform apply -target=snowflake_warehouse.warehouse \
                -target=snowflake_database.netflix_database \
                -target=snowflake_schema.netflix_schema \
                -target=snowflake_table.netflix_table \
                -target=snowflake_storage_integration.s3_int \
                -target=snowflake_stage.s3_stage \
                --auto-approve

# Get AWS_IAM User ARN and External ID for Snowflake Storage Integration
echo -n "STORAGE_AWS_IAM_USER_ARN:"; snowsql -c karasuit -q "DESC INTEGRATION S3_INT;" | grep STORAGE_AWS_IAM_USER_ARN | sed -E 's/.*\|\s*(arn:aws:[^|]+)\s*\|.*/\1/'
echo -n "STORAGE_AWS_EXTERNAL_ID:"; snowsql -c karasuit -q "DESC INTEGRATION S3_INT;" | grep STORAGE_AWS_EXTERNAL_ID | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}'
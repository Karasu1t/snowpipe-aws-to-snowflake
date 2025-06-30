#Wear House
resource "snowflake_warehouse" "warehouse" {
  name            = "SNOWFLAKE_WAREHOUSE"
  warehouse_size  = "XSMALL"
  auto_suspend    = 300
  auto_resume     = true
  initially_suspended = true
  comment         = "Terraform created warehouse"
}

#Database
resource "snowflake_database" "netflix_database" {
  name = "NETFLIX_DATABASE"
  comment = "Terraform created database"
}

#Schema
resource "snowflake_schema" "netflix_schema" {
  name     = "NETFLIX_SCHEMA"
  database = snowflake_database.netflix_database.name
   with_managed_access = true
  is_transient        = true
  comment             = "Terraform created schema"

  data_retention_time_in_days                   = 1
  replace_invalid_characters                    = false
  log_level                                     = "INFO"
  trace_level                                   = "ALWAYS"
  suspend_task_after_num_failures               = 3
  task_auto_retry_attempts                      = 3
  user_task_managed_initial_warehouse_size      = "XSMALL"
  user_task_timeout_ms                          = 1200000
  user_task_minimum_trigger_interval_in_seconds = 60
  quoted_identifiers_ignore_case                = false
  enable_console_output                         = false
  pipe_execution_paused                         = false
}

resource "snowflake_table" "netflix_table" {
  database                    = snowflake_database.netflix_database.name
  schema                      = snowflake_schema.netflix_schema.name
  name                        = "NETFLIX_TABLE"
  comment                     = "Terraform created table"
  cluster_by                  = ["DATE"]
  data_retention_time_in_days = snowflake_schema.netflix_schema.data_retention_time_in_days
  change_tracking             = false

  column {
    name     = "DATE"
    type     = "DATE"
    nullable = true
  }

  column {
    name     = "CLOSE"
    type     = "NUMBER(20,16)"
    nullable = false
  }

  column {
    name     = "HIGH"
    type     = "NUMBER(20,16)"
    nullable = false
  }

  column {
    name     = "LOW"
    type     = "NUMBER(20,16)"
    nullable = false
  }

  column {
    name     = "OPEN"
    type     = "NUMBER(20,16)"
    nullable = false
  }

  column {
    name     = "VOLUME"
    type     = "NUMBER"
    nullable = false
  }
}

# storage_integration
resource "snowflake_storage_integration" "s3_int" {
  name                      = "S3_INT"
  storage_provider          = "S3"
  storage_aws_role_arn      = "arn:aws:iam::${local.aws_accountid}:role/${local.aws_iamrole_name}"
  storage_allowed_locations = ["s3://${local.aws_s3_bucket}/raw"]
  enabled                   = true
}

# s3 stage
resource "snowflake_stage" "s3_stage" {
  name                 = "S3_STAGE"
  database             = snowflake_database.netflix_database.name
  schema               = snowflake_schema.netflix_schema.name
  url                  = "s3://${local.aws_s3_bucket}/raw"
  storage_integration  = snowflake_storage_integration.s3_int.name
  comment              = "S3 stage for Snowpipe"
}

resource "snowflake_pipe" "s3_pipe" {
  database = snowflake_schema.netflix_schema.database
  schema   = snowflake_schema.netflix_schema.name
  name     = "NETFLIX_PIPE"
  auto_ingest = true
  comment     = "Pipe to load data from S3"

  copy_statement = <<EOT
COPY INTO ${snowflake_schema.netflix_schema.database}.${snowflake_schema.netflix_schema.name}.${snowflake_table.netflix_table.name}
FROM @${snowflake_database.netflix_database.name}.${snowflake_schema.netflix_schema.name}.${snowflake_stage.s3_stage.name}
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
ON_ERROR = 'SKIP_FILE'
EOT

  depends_on = [
    snowflake_table.netflix_table,
    snowflake_stage.s3_stage
  ]
}
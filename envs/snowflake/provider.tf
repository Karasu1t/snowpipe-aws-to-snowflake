terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "2.2.0"
    }
  }
}

provider "snowflake" {
  preview_features_enabled = [
    "snowflake_table_resource",
    "snowflake_storage_integration_resource",
    "snowflake_stage_resource",
    "snowflake_pipe_resource"
  ]
}
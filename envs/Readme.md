# Snowflake × AWS Snowpipe 環境構築手順（Terraform + Shell）

このプロジェクトは、AWS S3 バケットに CSV ファイルをアップロードすると、自動的に Snowflake にロードされるパイプライン（Snowpipe）を Terraform で IaC 化する構成です。  
項番 ① ～ ③ については setup.sh を実行することでショートカット出来ます(手作業の軽減化)  
ただし、tf ファイルの意図しない書き換えを防ぐために全量の sh 化はしていない

---

## 🛠 環境構築手順

### ① ダミーの IAM ロール / S3 バケットを作成（初期セットアップ）

```bash
cd aws

# IAMロール作成
aws iam create-role \
  --role-name SnowflakeRole \
  --assume-role-policy-document file://trust-policy.json

# S3バケット作成
aws s3api create-bucket \
  --bucket karasuit-etl-bucket \
  --region ap-northeast-1 \
  --create-bucket-configuration LocationConstraint=ap-northeast-1
```

### ② Terraform に事前作成リソースをインポート

```bash
terraform import module.s3_snowpipe.aws_iam_role.snowflake_role SnowflakeRole
terraform import module.s3_snowpipe.aws_s3_bucket.etl-bucket karasuit-etl-bucket
```

### ③ Snowflake（PIPE 以外）を apply

```bash
cd ../snowflake

terraform apply -target=snowflake_warehouse.warehouse \
                -target=snowflake_database.netflix_database \
                -target=snowflake_schema.netflix_schema \
                -target=snowflake_table.netflix_table \
                -target=snowflake_storage_integration.s3_int \
                -target=snowflake_stage.s3_stage \
                --auto-approve
```

### ④ Storage Integration の認証情報を取得

```bash
snowsql -c karasuit -q "DESC INTEGRATION S3_INT;" | grep STORAGE_AWS_IAM_USER_ARN
snowsql -c karasuit -q "DESC INTEGRATION S3_INT;" | grep STORAGE_AWS_EXTERNAL_ID

取得した STORAGE_AWS_IAM_USER_ARN と STORAGE_AWS_EXTERNAL_ID を aws/locals.tf に設定。
また、IAMロールの assume_role_policy（iam.tf）にも反映。
```

### ⑤ IAM ロールの Terraform Apply

```bash
cd ../aws
terraform apply -target=module.s3_snowpipe.aws_iam_role.snowflake_role
```

### ⑥ Snowflake PIPE を作成

```bash
cd ../snowflake
terraform apply

作成された PIPE の Notification ARN を取得：

snowsql -c karasuit -q "DESC PIPE NETFLIX_DATABASE.NETFLIX_SCHEMA.NETFILIX_PIPE;" | grep NOTIFICATION_CHANNEL
取得した ARN を aws/storage.tf の queue_arn に設定。
```

### ⑦ S3 イベント通知の Terraform Apply

```bash
cd ../aws
terraform apply
```

### ⑧ 動作確認

```bash
karasuit-etl-bucket/raw/ 配下に Netflix_stock_data.csv をアップロード

Snowpipe により NETFLIX_TABLE に自動ロードされることを確認
```

### 補足

同一ファイル名で再アップロードしても Snowpipe は取り込まない（重複防止）
locals.tf の書き換えで変数の一元管理が可能

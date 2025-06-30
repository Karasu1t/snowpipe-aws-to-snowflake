# ------------------------------------
# IAM ポリシー/ロール
# ------------------------------------
resource "aws_iam_role" "snowflake_role" {
  name = "SnowflakeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        AWS = "${var.aws_iam_role_principal}" # e.g., "arn:aws:iam::123456789012:user/snowflake_user"
      },
      Action = "sts:AssumeRole",
      Condition = {
        StringEquals = {
          "sts:ExternalId" = "${var.externalid}" # e.g., "my-external-id"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "snowflake_s3_policy" {
  name = "SnowflakePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      Resource = [
        "${aws_s3_bucket.etl-bucket.arn}",
        "${aws_s3_bucket.etl-bucket.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.snowflake_role.name
  policy_arn = aws_iam_policy.snowflake_s3_policy.arn
}
resource "aws_s3_bucket" "etl-bucket" {
  bucket        = "${var.project}-etl-bucket"
  force_destroy = true
}

#オブジェクトの所有権をバケット所有者に変更
resource "aws_s3_bucket_ownership_controls" "bucket_ownership_control" {
  bucket = aws_s3_bucket.etl-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = aws_s3_bucket.etl-bucket.id

  queue {
    queue_arn     = "${var.notification_channel}"
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/"
  }
}
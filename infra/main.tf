resource "aws_s3_bucket" "iac_baseline" {
  bucket_prefix = "iac-course-baseline-"

  tags = {
    Environment = "lab"
  }
}

resource "aws_s3_bucket_public_access_block" "iac_baseline" {
  bucket                  = aws_s3_bucket.iac_baseline.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

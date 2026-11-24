resource "aws_s3_bucket" "sin_etiqueta" {
  bucket_prefix = "iac-policy-fail-"

  tags = {
    Owner = "security-course"
  }
}

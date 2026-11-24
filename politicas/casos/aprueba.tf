resource "aws_s3_bucket" "con_etiqueta" {
  bucket_prefix = "iac-policy-pass-"

  tags = {
    Environment = "lab"
  }
}

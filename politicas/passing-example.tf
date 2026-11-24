resource "aws_s3_bucket" "policy_passes" {
  bucket = "policy-passes-example"

  tags = {
    Environment = "lab"
    Owner       = "security-course"
    CostCenter  = "education"
  }
}


resource "aws_s3_bucket" "iac_baseline" {
  # checkov:skip=CKV_ORG_2:EXC-IAC-001 (aprobación simulada de laboratorio). Bucket de análisis estático sin despliegue ni datos; responsable registrado en el informe. Vence 2026-12-23.
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

variable "source_kms_key_arn" {
  type        = string
  description = "ARN de la clave KMS de la región de origen."
}

variable "access_log_bucket_name" {
  type        = string
  description = "Bucket existente en la misma cuenta y región, con permiso para recibir registros de acceso de S3."
}

variable "replica_bucket_arn" {
  type        = string
  description = "ARN del bucket de destino existente en otra región y con versionado habilitado."
}

variable "replica_kms_key_arn" {
  type        = string
  description = "ARN de la clave KMS en la región del bucket de réplica."
}

variable "replication_role_arn" {
  type        = string
  description = "ARN del rol que S3 puede asumir y que tiene los permisos de replicación y de uso de ambas claves KMS."
}

resource "aws_s3_bucket_versioning" "iac_baseline" {
  bucket = aws_s3_bucket.iac_baseline.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "iac_baseline" {
  bucket = aws_s3_bucket.iac_baseline.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.source_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_logging" "iac_baseline" {
  bucket        = aws_s3_bucket.iac_baseline.id
  target_bucket = var.access_log_bucket_name
  target_prefix = "iac-baseline/"
}

resource "aws_s3_bucket_notification" "iac_baseline" {
  bucket      = aws_s3_bucket.iac_baseline.id
  eventbridge = true
}

resource "aws_s3_bucket_lifecycle_configuration" "iac_baseline" {
  bucket     = aws_s3_bucket.iac_baseline.id
  depends_on = [aws_s3_bucket_versioning.iac_baseline]

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-old-noncurrent-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "iac_baseline" {
  bucket = aws_s3_bucket.iac_baseline.id
  role   = var.replication_role_arn
  depends_on = [
    aws_s3_bucket_versioning.iac_baseline,
    aws_s3_bucket_server_side_encryption_configuration.iac_baseline,
  ]

  rule {
    id       = "cross-region-replica"
    priority = 1
    status   = "Enabled"
    filter {}

    delete_marker_replication {
      status = "Disabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket = var.replica_bucket_arn
      encryption_configuration {
        replica_kms_key_id = var.replica_kms_key_arn
      }
    }
  }
}

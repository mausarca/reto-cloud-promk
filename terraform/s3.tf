resource "aws_s3_bucket" "static" {
  bucket        = "s3-assets-${local.suffix}"
  force_destroy = true
}

# Bloqueo estricto de accesos públicos
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cifrado en reposo del lado del servidor (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "crypto" {
  bucket = aws_s3_bucket.static.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

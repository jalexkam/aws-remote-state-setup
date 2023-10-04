

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  profile = "alex-meli-card-admincli"
  region  = var.aws_region
}

##################################################################################
# RESOURCES
##################################################################################

resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

locals {

  dynamodb_table_name = "${var.aws_dynamodb_table}-${random_integer.rand.result}"
  bucket_name         = "${var.aws_bucket}-${random_integer.rand.result}"
}

resource "aws_s3_bucket" "state_bucket" {
  bucket = local.bucket_name
  tags = {
    Project  = var.project
    Location = var.aws_region
  }
  force_destroy = true
}


resource "aws_s3_bucket_versioning" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_statelock" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Project  = var.project
    Location = var.aws_region
  }
}


##################################################################################
# OUTPUTS 
##################################################################################
output "s3_bucket" {
  value = aws_s3_bucket.state_bucket.id
}

output "dynamodb_statelock" {
  value = aws_dynamodb_table.terraform_statelock.name
}



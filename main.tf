

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

resource "aws_dynamodb_table" "terraform_statelock" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "state_bucket" {
  bucket = local.bucket_name
  tags = {
    Project  = "Alexandre"
    Location = "Cardiff"
  }
  force_destroy = true
}

# resource "aws_s3_bucket_acl" "state_bucket" {
#   bucket = aws_s3_bucket.state_bucket.id
#   acl    = "private"
# }

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

resource "aws_s3_bucket_ownership_controls" "remote_state" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

# create group
resource "aws_iam_group" "bucket_full_access" {
  name = "${local.bucket_name}-full-access"
}

resource "aws_iam_group" "bucket_read_only" {
  name = "${local.bucket_name}-read-only"
}

# Add members to the group

resource "aws_iam_group_membership" "full_access" {
  name  = "${local.bucket_name}-full-access"
  users = var.full_access_users
  group = aws_iam_group.bucket_full_access.name
}

resource "aws_iam_group_membership" "read_only" {
  name  = "${local.bucket_name}-read-only"
  users = var.read_only_users
  group = aws_iam_group.bucket_read_only.name
}

resource "aws_iam_group_policy" "full_access" {
  name  = "${local.bucket_name}-full-access"
  group = aws_iam_group.bucket_full_access.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${local.bucket_name}",
                "arn:aws:s3:::${local.bucket_name}/*"
            ]
        },
                {
            "Effect": "Allow",
            "Action": ["dynamodb:*"],
            "Resource": [
                "${aws_dynamodb_table.terraform_statelock.arn}"
            ]
        }
   ]
}
EOF
}

resource "aws_iam_group_policy" "read_only" {
  name  = "${local.bucket_name}-read-only"
  group = aws_iam_group.bucket_read_only.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::${local.bucket_name}",
                "arn:aws:s3:::${local.bucket_name}/*"
            ]
        }
   ]
}
EOF
}

output "s3_bucket" {
  value = aws_s3_bucket.state_bucket.id
}

output "dynamodb_statelock" {
  value = aws_dynamodb_table.terraform_statelock.name
}


# ##################################################################################
# # OUTPUT
# ##################################################################################


# provider "aws" {
#   profile = "alex-meli-card-admincli"
#   region  = var.aws_region
# }

# ##################################################################################
# # RESOURCES
# ##################################################################################

# resource "random_integer" "rand" {
#   min = 10000
#   max = 99999
# }

# locals {

#   dynamodb_table_name = "${var.aws_dynamodb_table}-${random_integer.rand.result}"
#   bucket_name         = "${var.aws_bucket}-${random_integer.rand.result}"
# }

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = local.bucket_name

#   # Prevent accidental deletion of this S3 bucket
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_s3_bucket_versioning" "enabled" {
#   bucket = aws_s3_bucket.terraform_state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
# resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "public_access" {
#   bucket                  = aws_s3_bucket.terraform_state.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = local.dynamodb_table_name
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }

# output "s3_bucket" {
#   value = aws_s3_bucket.terraform_state
# }

# output "dynamodb_statelock" {
#   value = aws_dynamodb_table.terraform_locks.name
# }


variable "aws_profile" {
  description = "AWS Profile"
  type        = string
}

variable "aws_bucket" {
  description = "Bucket to hold tfstate file of projects"
  type        = string
}

variable "aws_dynamodb_table" {
  description = "Table to hold lock values of projects"
  type        = string
}

variable "aws_region" {
  description = "aws region"
  type        = string
}

variable "full_access_users" {
  description = "Full access users list"
  type        = list(string)
}
variable "read_only_users" {
  description = "read only users list"
  type        = list(string)
}

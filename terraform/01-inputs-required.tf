variable "aws_deploy_region" {
  description = "AWS region to deploy to"
  type        = string
}

variable "aws_deploy_account" {
  description = "AWS id to deploy to"
  type        = string
}

variable "aws_deploy_iam_role_name" {
  description = "AWS IAM role name to assume for deployment"
  type        = string
}

variable "aws_profile" {
  type = string
}

variable "identifier_prefix" {
  description = "A prefix for naming resources"
  type        = string
}

variable "aws_availability_zone_a" {
  description = "AWS availability zone a"
  type        = string
}

variable "aws_availability_zone_b" {
  description = "AWS availability zone b"
  type        = string
}

variable "cidr_block_subnet_a" {
  description = "CIDR range for the subnet a"
  type        = string
}

variable "cidr_block_subnet_b" {
  description = "CIDR range for the subnet b"
  type        = string
}

variable "my_ip_address" {
  description = "Local IP address"
  type        = string
}

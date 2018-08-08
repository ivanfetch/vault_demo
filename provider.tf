# Configure the AWS Terraform provider.
#
# These variables define the region and AWS profile name to use.

variable "region" {
  default = "eu-west-1"
}

variable "aws_profile" {
  default = ""
}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.aws_profile}"

  # The minimum version of the AWS provider to use.
  version = "~> 1.30"
}

provider "template" {
  # The minium version of the template provider to use.
  version = "~> 1.0"
}

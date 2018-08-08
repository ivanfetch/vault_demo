# A basic single availability zone VPC to support this demo.
# Some AWS accounts do not have default VPCs,
# or the default VPCs have been deleted. :)

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.95.0.0/16"
}

variable "vpc_subnet" {
  description = "The subnet for the single-AZ VPC."
  default     = "10.95.0.0/24"
}

variable "vpc_name" {
  description = "The Name tag for the VPC."
  default     = "Ivan Vault demo"
}

resource "aws_vpc" "demo" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name       = "${var.vpc_name}"
    created_by = "Terraform"
  }
}

resource "aws_internet_gateway" "demo" {
  vpc_id = "${aws_vpc.demo.id}"

  tags {
    Name       = "${var.vpc_name}"
    created_by = "Terraform"
  }
}

resource "aws_subnet" "demo" {
  vpc_id     = "${aws_vpc.demo.id}"
  cidr_block = "${var.vpc_subnet}"

  # Use availability zone b in the region configured in provider.tf
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags {
    Name       = "${var.vpc_name}"
    created_by = "Terraform"
  }
}

resource "aws_route_table" "demo" {
  vpc_id = "${aws_vpc.demo.id}"

  tags {
    Name       = "${var.vpc_name}"
    created_by = "Terraform"
  }
}

resource "aws_route" "default" {
  route_table_id         = "${aws_route_table.demo.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.demo.id}"
}

resource "aws_route_table_association" "demo" {
  subnet_id      = "${aws_subnet.demo.id}"
  route_table_id = "${aws_route_table.demo.id}"
}

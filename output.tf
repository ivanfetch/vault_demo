# Terraform outputs to share information about resources created by Terraform.
# Some of these are used by the vault-demo.sh script.

output "ec2_private_ip" {
  value = ["${aws_instance.ec2.private_ip}"]
}

output "ec2_public_ip" {
  value = ["${aws_instance.ec2.public_ip}"]
}

output "ec2_public_dns" {
  value = ["${aws_instance.ec2.public_dns}"]
}

output "ec2_id" {
  value = ["${aws_instance.ec2.id}"]
}

output "securitygroup_id" {
  value = ["${aws_security_group.web_ssh.id}"]
}

output "vpc_id" {
  value = "${aws_vpc.demo.id}"
}

output "vpc_cidr_block" {
  value = "${aws_vpc.demo.cidr_block}"
}

output "subnet_cidr_block" {
  value = ["${aws_subnet.demo.cidr_block}"]
}

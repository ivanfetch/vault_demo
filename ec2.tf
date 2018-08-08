# Create an Ubuntu 18.04 EC2,
# and install a Vault demo with a Nginx proxy to serve the user interface.

# This gets the latest AMI for Ubuntu 18.04
data "aws_ami" "ubuntu18_04" {
  most_recent = true

  # THis is Canonical
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

# This is a user data template which installs Vault with a Nginx proxy
data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.tmpl")}"
}

# This AWS SSH key pair uses the key created by the vault-demo.sh script.
resource "aws_key_pair" "demo" {
  key_name_prefix = "Ivan Vault demo-"
  public_key      = "${file("id_rsa.pub")}"
}

resource "aws_instance" "ec2" {
  tags = {
    Name       = "Ivan Vault Demo"
    created_by = "Terraform"
  }

  volume_tags = {
    Name       = "Ivan Vault Demo"
    created_by = "Terraform"
  }

  ami                         = "${data.aws_ami.ubuntu18_04.id}"
  instance_type               = "t2.nano"
  subnet_id                   = "${aws_subnet.demo.id}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.web_ssh.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
  }

  user_data = "${data.template_file.user_data.rendered}"
  key_name  = "${aws_key_pair.demo.id}"

  lifecycle {
    # DO not recreate EC2 instances if a newer AMI becomes available,
    # or the SSH key pair changes.
    # If you want to recreate an instance under one of these conditions,
    # "taint" it in Terraform to force it to be recreated.
    # E.G. terraform taint aws_instance.ec2
    ignore_changes = ["ami", "key_name"]
  }
}

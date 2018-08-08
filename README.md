# Vault Demo

This repository creates an EC2 instance running [Hashicorp Vault][], using the [filesystem storage backend][] to demo the Vault web user interface. The Vault user interface can be accessed over HTTPS from the Internet. The `vault` command-line can also be used by connecting to the EC2 instance over SSH from the Internet. A supporting [VPC][] and [security group][] are also created.

This is meant as a demo environment for Vault, and **should not be used** in production.


## Prerequisites
This demo has been tested on Mac OS X. It requires either that [Terraform][] is in your path, or that the `curl`, `shasum`, and `unzip`, commands are available to download Terraform into this repository.

By default the EC2 instance and security group are created in the `eu-west-1` AWS region, using the default AWS profile. To change either of these, edit the `provider.tf` file and change the `default` line for the `region` or `aws_profile` variables.

A basic VPC is created using a single availability zone of `b` in the region configured in `provider.tf`. For example, if using the region `eu-west-1`, the VPC and EC2 instance will be created in the `eu-west-1b` availability zone. To change the availability zone, edit the `availability_zone` line of `vpc.tf`.

When accessing the Vault UI, you will need to acknowledge that the HTTPS SSL certificate is self signed; not from a valid certificate authority. This may require administrative access to add the certificate to your keychain, or if you do not want to do this, using a "private browsing" window.

## Creating The Demo
Run the `vault-demo.sh` shell script, which will:

* Create an SSH key which can be used to SSH into the EC2 instance.
* Verify [Terraform][] is in your path, and if not, download it to this repository.
* Use Terraform to create an EC2 instance and security group which allows the Internet to access SSH, HTTP, and HTTPS.
	* Vault and an Nginx proxy will be configured by [AWS user data][].
* Wait for the Nginx web server to respond on the EC2 instance.
* Retrieve the Vault keys and initial root token from the EC2 instance and display them so you can [unseal the Vault][] using the UI.
* Open your default web browser to the Vault user interface on the EC2 instance.
	* Note you will need to accept the self-signed SSL certificate in your browser.

Please keep the `terraform.tfstate` file which Terraform generates, until you have used Terraform to clean up the resources created by this demo.

## Clean Up
When you are done with this demo, clean up the AWS resources by running `terraform destroy` from within this repository directory. IF you didn't already have Terraform in your path, use `./terraform destroy` to use the copy of Terraform which this script downloaded. Keep the `terraform.tfstate` file so that Terraform is aware of the AWS resources that its managing until you have destroyed this demo.

## Known Issues / Room For Improvement

* IF the EC2 instance is stopped then started again, it will have a different public IP address which no longer matches the CN of the SSL certificate. I didn't think this demo warranted an AWS Elastic IP Address, which could incur charges if the EC2 is stopped and the EIP is not in use.
* Vault does not use SSL - while this isn't an issue on the loopback interface between Nginx and Vault, it might be possible to use the `vault` CLI from a workstation to remotely access this demo if Vault managed SSL instead of Nginx.
* It may be strange or inconvenient that the VPC, and therefore the EC2 instance, is created in availability zone `B` of the AWS region.



[Hashicorp Vault]: https://www.vaultproject.io/

[filesystem storage backend]: https://www.vaultproject.io/docs/configuration/storage/filesystem.html

[VPC]: https://aws.amazon.com/vpc/

[security group]: https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_SecurityGroups.html

[Terraform]: http://www.terraform.io

[AWS user data]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html

[unseal the Vault]: https://www.vaultproject.io/docs/concepts/seal.html

#!/usr/bin/env bash
#
# Use Terraform to deploy an EC2 instance, running a Hashicorp Vault demo.
# Terraform will be installed if it is not found in the path.
# Vault will use the filesystem storage backend,
# and its UI will be proxied by Nginx.
#
# This script waits for Nginx to respond on the EC2 instance ,
# retrieves the Vault keys and root token from the EC2 instance,
# and opens the default web browser to the Vault UI.
# Running this script subsequent times will re-run Terraform
# and repeat the above steps to display Vault info again.
#
#
# IF Terraform is not already in your path,
# THis specifies the version to download, and its checksum.
terraform_url='https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_darwin_amd64.zip'
terraform_checksum="6514a8fe5a344c5b8819c7f32745cd571f58092ffc9bbe9ea3639799b97ced5f"

# ##### Nothing needs to be edited beyond this point #####


# Operate in the directory containing this script, and included it in the path,
# in case Terraform needs to be downloaded.
cd $(dirname $0)
export     PATH=`pwd`:$PATH


# Display a notice from this script, differentiated from other output
function notice {
  echo "$(basename $0): $@"
}


# Display an error from this script, differentiated from other output
function error {
  notice $@
  notice This script will not continue.
  exit 1
}


# Verify Terraform is in the path, and if not, download it to this directory
function install_terraform {
  which -s terraform
  if [ $? -gt 0 ] ; then
    notice Downloading Terraform as it was not found in your path nor in $(pwd). . .
    curl -sfo terraform.zip "${terraform_url}"
    if [ ! -r terraform.zip ] ; then
      error The downoad of Terraform failed. Please check that the URL in $0 is correct: ${terraform_url}
    fi

    local checksum=$(shasum -a 256 terraform.zip |awk '{print $1};')
    if [ "$checksum" != "$terraform_checksum" ] ; then
      error The checksum ${checksum} did not match ${terraform_checksum} - I recommend downloading Terraform from http://terraform.io and placing it in your path.
    fi

    unzip -qo terraform.zip && rm terraform.zip
    if [ ! -x terraform ] ; then
      error Extracting the Terraform zip file failed.
    fi
  fi

  notice Using Terraform at $(which terraform)
}


# Create an SSH key if one does not already exist in this directory
function create_ssh_key {
  if [ ! -r id_rsa ] ; then
    notice Creating an SSH key in $(pwd) to be used with Terraform. . .
    ssh-keygen -P '' -f ./id_rsa
  fi
}


# Wait for the web app to respond, and retrieve Vault keys from EC2
function wait_for_app {
  # How long to wait for the EC2 to respond
  local count_down_secs=60
  # THe IP to check with curl, and retrieve Vault info from
  local ip_address=$(terraform output ec2_public_ip)
  # Store the output and return value from curl
  local curl_output
  local curl_return=1

  notice Waiting for the EC2 instance to become ready on ${ip_address}. . .

  local count_down=$count_down_secs

  while [ $count_down -gt 0 ] ; do
    curl_output=$(curl -s -k http://${ip_address}/ui)
    curl_return=$?

    if [ $curl_return -eq 0 ] ; then
      notice The application is ready after $(expr $count_down_secs - $count_down) seconds
      break
    else
      count_down=$(expr $count_down - 1)
      sleep 1
    fi
  done

  if [ $curl_return -eq 0 ] ; then
    notice The Vault user interface is ready at http://${ip_address}
    notice You can also use the vault command-line from the EC2 instance, to login: ssh -i $(pwd)/id_rsa ubuntu@${ip_address}
    echo
    notice Here are the keys you will need to unseal Vault, and the root token you will need to login to Vault:

    # SSH to the EC2, ignoring the host key and not updating known_hosts,
    # retrieving a text file containing info from `vault operator init`
    ssh -q \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -i $(pwd)/id_rsa ubuntu@${ip_address} 'cat /vault_init.txt'
    notice The above information can also be found on the EC2 instance, in /vault_init.txt

    notice Visiting http://${ip_address} will redirect to an HTTPS URL, which has a self-signed SSL certificate you will need to accept.

    open http://${ip_address}/ui
  else
    notice The web app is still not available at http://${ip_address} - you can SSH to troubleshoot, using the command: ssh -i $(pwd)/id_rsa ubuntu@${ip_address}
    notice Using curl to access the EC2 instance returned: $curl_output
  fi
}


install_terraform
create_ssh_key

# This is safe to run multiple times on an existing Terraform root module.
notice Initializing Terraform. . .
terraform init



# IF `terraform plan` has changes to make, apply them
notice Running \`terraform plan\` to see whether changes need to be applied. . .
plan_output=$(terraform plan -no-color -detailed-exitcode 2>&1)

# Parse the Terraform exit code, returned by the `-detailed-exitcode` switch
case $? in
  2)
    notice There are Terraform changes to apply - doing that now. . .
    terraform apply -no-color -auto-approve
    if [ $? -gt 0 ] ; then
      error Terraform returned an error, please see above
    fi

    wait_for_app
  ;;
  0)
    notice There are no changes for Terraform to apply
    # Still verify the app responds and retrieve Vault info
    wait_for_app
  ;;
  *)
    error Terraform returned this error: ${plan_output}
  ;;
esac


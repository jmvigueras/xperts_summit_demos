#!/bin/bash

# Specify the path to your Terraform state file
terraform_state_file="../../1_day0_IaC_ftnt_aws_gcp_k8s/terraform.tfstate"

# Generate ANSIBLE HOST file
ansible_host_file="hosts"

# APP general variables
APP_1_PORT="31000"
APP_2_PORT="31001"
FGT_ADMIN_PORT=8443

# Read Terraform output and generate variable files
CSPS=('aws' 'gcp') 

for csp in "${CSPS[@]}"
do
    # Use jq to extract the value of the specified output variable
    FGT_PUBLIC_IP=$(jq -r ".outputs.fgt_values.value.$csp.PUBLIC_IP" "$terraform_state_file")
    FGT_TOKEN=$(jq -r ".outputs.fgt_values.value.$csp.TOKEN" "$terraform_state_file")
    FGT_EXTERNAL_IP=$(jq -r ".outputs.fgt_values.value.$csp.EXTERNAL_IP" "$terraform_state_file")
    FGT_MAPPED_IP=$(jq -r ".outputs.fgt_values.value.$csp.MAPPED_IP" "$terraform_state_file")

    echo "Terraform outputs for $csp: FGT_HOST: $FGT_PUBLIC_IP TOKEN: $FGT_TOKEN"

    # Create host.ini from template using sed
    echo "Adding fgt $csp to hosts file ..."
    sed -e "s/__CSP__/$csp/" \
        -e "s/__FGT_PUBLIC_IP__/$FGT_PUBLIC_IP/" \
        -e "s/__FGT_ACCESS_TOKEN__/$FGT_TOKEN/" \
        "./templates/hosts" \
        >> "../$ansible_host_file"

    # Create Ansible role variables
    echo "Generating vars for role $csp ..."
    sed -e "s/__FGT_ADMIN_PORT__/$FGT_ADMIN_PORT/" \
        -e "s/__FGT_EXT_IP__/$FGT_EXTERNAL_IP/" \
        -e "s/__APP_1_PORT__/$APP_1_PORT/" \
        -e "s/__APP_2_PORT__/$APP_2_PORT/" \
        -e "s/__MAPPED_IP__/$FGT_MAPPED_IP/" \
        "./templates/vars.yml" \
        > "../roles/$csp/vars/main.yml"

    # Create playbook
    echo "Add playbook role execution for $csp ..."
    sed -e "s/__ROLE__/$csp/" \
        "./templates/playbook.yml" \
        >> "../00-playbook.yml"
done

echo "DONE!"
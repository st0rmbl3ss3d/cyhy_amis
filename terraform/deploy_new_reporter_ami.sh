#!/usr/bin/env bash

# deploy_new_reporter_ami.sh
# deploy_new_reporter_ami.sh workspace_name

set -o nounset
set -o errexit
set -o pipefail

workspace=prod-a
if [ $# -ge 1 ]
then
    workspace=$1
fi

terraform workspace select "$workspace"

reporter_instance_id=$(terraform state show aws_instance.cyhy_reporter | \
                           grep "^id" | sed "s/^id *= \(.*\)/\1/")

# Terminate the existing reporter instance
aws ec2 terminate-instances --instance-ids "$reporter_instance_id"
aws ec2 wait instance-terminated --instance-ids "$reporter_instance_id"

terraform apply -var-file="$workspace.tfvars" \
          -target=aws_instance.cyhy_reporter \
          -target=aws_route53_record.cyhy_reporter_A \
          -target=aws_route53_record.cyhy_rev_reporter_PTR \
          -target=aws_security_group_rule.private_mongodb_ingress \
          -target=aws_volume_attachment.cyhy_reporter_data_attachment \
          -target=module.cyhy_reporter_ansible_provisioner
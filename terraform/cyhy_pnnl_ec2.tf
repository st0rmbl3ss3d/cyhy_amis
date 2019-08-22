data "aws_ami" "cyhy_pnnl" {
  filter {
    name = "name"
    values = [
      "mcdonnnj-pnnl-hvm-*-x86_64-ebs",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners      = [data.aws_caller_identity.current.account_id] # This is us
  most_recent = true
}

# IAM assume role policy document for the Mongo IAM role to be used by
# the Mongo EC2 instance
data "aws_iam_policy_document" "cyhy_pnnl_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The Mongo IAM role to be used by the Mongo EC2 instance
resource "aws_iam_role" "cyhy_pnnl_role" {
  assume_role_policy = data.aws_iam_policy_document.cyhy_pnnl_assume_role_doc.json
}

# The instance profile to be used by the CyHy Mongo EC2 instance.
resource "aws_iam_instance_profile" "cyhy_pnnl" {
  role = aws_iam_role.cyhy_pnnl_role.name
}

resource "aws_instance" "cyhy_pnnl" {
  ami                         = data.aws_ami.cyhy_pnnl.id
  instance_type               = local.production_workspace ? "t3.medium" : "t3.micro"
  availability_zone           = "${var.aws_region}${var.aws_availability_zone}"
  subnet_id                   = aws_subnet.cyhy_private_subnet.id
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 2000
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_private_sg.id,
  ]

  user_data_base64 = data.template_cloudinit_config.ssh_and_pnnl_cloud_init_tasks.rendered

  # Give this instance the access needed for archiving and doing daily
  # extracts
  iam_instance_profile = aws_iam_instance_profile.cyhy_pnnl.name

  tags = merge(
    var.tags,
    {
      "Name" = "CyHy PNNL"
    },
  )
}

# Provision the mongo EC2 instance via Ansible
# TODO when we start using multiple mongo, move this to a dyn_mongo module
# TODO see pattern of nmap and nessus
module "cyhy_pnnl_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'",
  ]
  envs = [
    "ANSIBLE_SSH_RETRIES=5",
    "host=${aws_instance.cyhy_pnnl.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=pnnl",
    "production_workspace=${local.production_workspace}",
    "aws_region=${var.aws_region}",
    "dmarc_import_aws_region=${var.dmarc_pnnl_import_aws_region}",
  ]
  playbook = "../ansible/playbook.yml"
  dry_run  = false
}

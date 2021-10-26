# The bastion EC2 instance
resource "aws_instance" "cyhy_bastion" {
  ami               = data.aws_ami.bastion.id
  instance_type     = "t3.small"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the public subnet
  subnet_id                   = aws_subnet.cyhy_public_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_bastion_sg.id,
  ]

  user_data_base64 = data.template_cloudinit_config.ssh_cloud_init_tasks.rendered

  tags = merge(
    var.tags,
    {
      "Name" = "CyHy Bastion"
    },
  )
  volume_tags = merge(
    var.tags,
    {
      "Name" = "CyHy Bastion"
    },
  )
}

# Provision the bastion EC2 instance via Ansible
module "cyhy_bastion_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no'",
  ]
  envs = [
    "host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_bastion",
  ]
  playbook = "../ansible/playbook.yml"
  dry_run  = false
}

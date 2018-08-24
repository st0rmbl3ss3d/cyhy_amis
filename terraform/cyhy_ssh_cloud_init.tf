# cloud-init commands for configuring ssh

data "template_file" "cyhy_user_ssh_setup" {
  template = "${file("scripts/cyhy_user_ssh_setup.yml")}"
}

data "template_cloudinit_config" "cyhy_ssh_cloud_init_tasks" {
  gzip = false
  base64_encode = false

  part {
    filename     = "user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.user_ssh_setup.rendered}"
  }

  part {
    filename     = "cyhy_user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cyhy_user_ssh_setup.rendered}"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

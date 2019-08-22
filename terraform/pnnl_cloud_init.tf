# cloud-init commands for configuring ssh and pnnl

data "template_cloudinit_config" "ssh_and_pnnl_cloud_init_tasks" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = data.template_file.user_ssh_setup.rendered
  }

  part {
    filename     = "cyhy_user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = data.template_file.cyhy_user_ssh_setup.rendered
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

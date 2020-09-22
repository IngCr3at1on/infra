data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.tpl")}"
  vars = {
    root_password = local.root_password
  }
}

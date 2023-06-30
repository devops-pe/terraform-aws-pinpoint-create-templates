#!create html template in pinpoint
#* depends 
#* - null_resource.html_validate_templates
#* - null_resource.html_replace_patterns_pinpoint
resource "null_resource" "html_email_pinpoint_create_or_update" {
  for_each = local.html_files_templates
  triggers = { always_run = timestamp() }
  depends_on = [
    null_resource.html_validate_templates,
    null_resource.html_replace_patterns_pinpoint,
    null_resource.html_minifier_pinpoint
  ]
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.command_html_pinpoint_create_or_update
    environment = {
      INDEX_HTML = "${local.base_path_template}/${each.key}"
      MAIN_YML   = "${local.base_path_template}/${replace(each.key, "index.html", "main.yml")}"
    }
  }
}

resource "null_resource" "push_pinpoint_create_or_update" {
  for_each = local.push_files_templates
  triggers = { always_run = timestamp() }
  depends_on = [
    null_resource.html_email_pinpoint_create_or_update
  ]
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.command_push_pinpoint_create_or_update
    environment = {
      MAIN_YML = "${local.base_path_template}/${each.key}"
    }
  }
}

resource "null_resource" "sms_pinpoint_create_or_update" {
  for_each = local.sms_files_templates
  triggers = { always_run = timestamp() }
  depends_on = [
    null_resource.push_pinpoint_create_or_update
  ]
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.command_sms_pinpoint_create_or_update
    environment = {
      MAIN_YML = "${local.base_path_template}/${each.key}"
    }
  }
}

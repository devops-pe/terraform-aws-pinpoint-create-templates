#*######################### HTML MINIFIER IN HTML #########################################
resource "null_resource" "html_minifier_pinpoint" {
  for_each = local.html_files_templates
  triggers = { always_run = timestamp() }
  depends_on = [
    null_resource.html_validate_templates,
    null_resource.html_replace_patterns_pinpoint
  ]
  provisioner "local-exec" {
    command     = local.command_html_minifier
    interpreter = ["bash", "-c"]
    environment = {
      INDEX_HTML = "${local.base_path_template}/${each.key}"
    }
  }
}
#?######################### FIN  HTML MINIFIER IN HTML #########################################

#!find html files and apply validation with html-validate(folders: files_template_dynamo_html, files: *.html, templates: *.html)
#*######################### HTML VALIDATE #########################################
#*in files_templates
resource "null_resource" "html_validate_templates" {
  for_each = local.html_files_templates
  triggers = { always_run = timestamp() }
  provisioner "local-exec" {
    command     = local.command_html_validate
    interpreter = ["bash", "-c"]
    environment = {
      INDEX_HTML = "${local.base_path_template}/${each.key}"
    }
  }
}

#?######################### FIN HTML VALIDATE #########################################

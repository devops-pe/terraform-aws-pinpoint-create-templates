#! after validation is done, replace patterns in html files
#*######################### REPLACE IN HTML #########################################

resource "null_resource" "html_replace_patterns_pinpoint" {
  for_each = local.html_files_templates
  triggers = { always_run = timestamp() }
  depends_on = [
    null_resource.html_validate_templates
  ]
  provisioner "local-exec" {
    command     = local.command_replace
    interpreter = ["bash", "-c"]
    environment = {
      JSON       = local.map_replace
      INDEX_HTML = "${local.base_path_template}/${each.key}"
    }
  }
}

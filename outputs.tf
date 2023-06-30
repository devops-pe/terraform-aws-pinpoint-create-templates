output "main" {
  value = {
    html_files_templates = local.html_files_templates
    push_files_templates = local.push_files_templates
    sms_files_templates  = local.sms_files_templates
  }
  description = "values of module stack-pinpoint-tpl"
}

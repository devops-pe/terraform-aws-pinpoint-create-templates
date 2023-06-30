variable "rules_off" {
  type        = list(string)
  description = "value of the rules_off html-validate command https://html-validate.org/usage/"
  # default = [
  #   "no-inline-style",
  #   "no-deprecated-attr",
  # ]
}
variable "map_replace" {
  type        = map(string)
  description = "value of the map(k,v) to replace in html files"
  # default = {}
}
#!variable base_path_template
variable "base_path_template" {
  type        = string
  description = "value of the base_path_template"
  default     = "templates"
}

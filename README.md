## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 4.20.0 |
| <a name="requirement_null"></a> [null](#requirement_null)                | >= 3.1.1  |

## Other Requirements

- Python 3.8 or higher
  - boto3
  - pyYAML
  - htmlmin
- nodejs 18 or higher
- npm 9 or higher(global install)

  - html-minifier
  - html-validate

- jo command line tool(create json file dynamic)
- yq command line tool(for extract information yaml file)

## Example Usage

```javascript
module "pinpoint_tpl" {
  source             = "../terraform-aws-pinpoint-create-templates"
  base_path_template = "files_templates"
  map_replace = {
    ENVIRONMENT_DOMAIN = "static.example.com"
  }
  rules_off = [
    "no-inline-style",
    "no-deprecated-attr",
    "element-permitted-content"
  ]
}
```

## Description

| Name               | Description                               |
| ------------------ | ----------------------------------------- |
| base_path_template | Path of directory templates               |
| map_replace        | Map of key value to replace in html files |
| rules_off          | List of rules off html-validate           |

## The html files be validate with [html-validate](https://html-validate.org/usage/)

```javascript
npm install -g html-validate
//ejemplo de uso
html-validate index.html
```

## _can exclude validate rules_

```javascript
html-validate index.html --config .htmlvalidate.json
```

## _the file .htmlvalidate.json containt_

```javascript
{
  "extends": ["html-validate:recommended"],
  "rules": {
    "no-inline-style": "off",
    "no-deprecated-attr": "off",
    "element-permitted-content": "off"
  }
}
```

## _Las reglas de exclusion son se pueden generar dynamicamente_

```javascript
html-validate index.html --config .htmlvalidate.json \
--set rules.no-inline-style=off \
--set rules.no-deprecated-attr=off \
--set rules.element-permitted-content=off
```

## in terraform use the following to generate the file .htmlvalidate.json we can create it dynamically

```javascript
locals {
  rules_off = [
    "no-inline-style",
    "no-deprecated-attr",
    "element-permitted-content"
  ]
}
```

## log for error html-validate

```javascript
|   Error: local-exec provisioner error
│
│   with module.pinpoint-tpl.null_resource.html_validate_templates["department/email/change_dir/index.html"],
│   on .terraform/modules/pinpoint-tpl/validate.html.tf line 20, in resource "null_resource" "html_validate_templates":
│   20:   provisioner "local-exec" {
│
│ Error running command 'HTML_VALIDATE=$(jo -p \
│       extends="$(jo -a html-validate:recommended)" \
│       rules="$(jo -p no-inline-style=off no-deprecated-attr=off element-permitted-content=off)"
│ )
│ echo $HTML_VALIDATE > .htmlvalidate.json
│ html-validate --config .htmlvalidate.json $INDEX_HTML
│ ': exit status 1. Output:
│ /app/files_templates/department/email/change_dir/index.html
│     4:27  error  Expected omitted end tag <meta> instead of self-closing element <meta/>         void-style
│     5:58  error  Expected omitted end tag <meta> instead of self-closing element <meta/>         void-style
│     6:75  error  Expected omitted end tag <meta> instead of self-closing element <meta/>         void-style
│    10:5   error  Expected omitted end tag <link> instead of self-closing element <link/>         void-style
│   273:12  error  <th> element must have a valid scope attribute: row, col, rowgroup or colgroup  wcag/h63
│   279:15  error  Expected omitted end tag <img> instead of self-closing element <img/>           void-style
│   285:12  error  <th> element must have a valid scope attribute: row, col, rowgroup or colgroup  wcag/h63
│   291:15  error  Expected omitted end tag <img> instead of self-closing element <img/>           void-style
│   341:21  error  Expected omitted end tag <img> instead of self-closing element <img/>           void-style
│   357:21  error  Expected omitted end tag <img> instead of self-closing element <img/>           void-style
│   373:21  error  Expected omitted end tag <img> instead of self-closing element <img/>           void-style
│
│ ✖ 11 problems (11 errors, 0 warnings)
│
│ More information:
│   https://html-validate.org/rules/void-style.html
│   https://html-validate.org/rules/wcag/h63.html
```

- for _email_ se need two files in each folder:
  - index.html
  - main.yml

### _Example_

```javascript
├── email
|   ├── email_attachment
│       ├── index.html
│       └── main.yml
```

- in the _main.yml_ should be the following:
  ```yaml
  subject: "HOLA {{name}}"
  name: "email_change"
  ```
- Para _inbox_ needs this file in each yaml file:
  ### _Example_
  ```javascript
  ├── inbox
  |   ├── inbox_attachment
  │       └── main.inbox.yml
  ```
  - main.inbox.yml
  - example:
    ```yaml
    name: "hi"
    version: 1
    content: "hi {{name}}!"
    ```
- for _push_ needs this file in each yaml file:
  ### _Example_
  ```javascript
  ├── push
  |   ├── push_attachment
  │       └── main.push.yml
  ```
  - main.push.yml
  - example:
    ```yaml
    name: "hola"
    version: 1
    content: "¡hola {{name}}!"
    ```
- for _sms_ needs this file in each yaml file:
  ### _Example_
  ```javascript
  ├── sms
  |   ├── sms_attachment
  │       └── main.sms.yml
  ```
  - main.push.yml
  - example:
    ```yaml
    name: "sms_template"
    body: "Hola"
    ```

## Providers

| Name                                                | Version  |
| --------------------------------------------------- | -------- |
| <a name="provider_null"></a> [null](#provider_null) | >= 3.1.1 |

## Resources

| Name                                                                                                                                        | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [null_resource.html_email_pinpoint_create_or_update](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.html_minifier_pinpoint](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)               | resource |
| [null_resource.html_replace_patterns_pinpoint](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)       | resource |
| [null_resource.html_validate_templates](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)              | resource |
| [null_resource.push_pinpoint_create_or_update](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)       | resource |
| [null_resource.sms_pinpoint_create_or_update](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)        | resource |

## Inputs

| Name                                                                                    | Description                                                                   | Type           | Default       | Required |
| --------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- | -------------- | ------------- | :------: |
| <a name="input_base_path_template"></a> [base_path_template](#input_base_path_template) | value of the base_path_template                                               | `string`       | `"templates"` |    no    |
| <a name="input_map_replace"></a> [map_replace](#input_map_replace)                      | value of the map(k,v) to replace in html files                                | `map(string)`  | n/a           |   yes    |
| <a name="input_rules_off"></a> [rules_off](#input_rules_off)                            | value of the rules_off html-validate command https://html-validate.org/usage/ | `list(string)` | n/a           |   yes    |

## Outputs

| Name                                            | Description                         |
| ----------------------------------------------- | ----------------------------------- |
| <a name="output_main"></a> [main](#output_main) | values of module stack-pinpoint-tpl |

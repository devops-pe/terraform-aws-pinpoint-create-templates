# data "aws_region" "main" {}
# data "aws_caller_identity" "main" {}
locals {
  base_path_template = "${path.cwd}/${var.base_path_template}"
  #* para pinpoint
  html_files_templates = fileset(local.base_path_template, "**/*.html")
  push_files_templates = fileset(local.base_path_template, "**/main.push.yml")
  sms_files_templates  = fileset(local.base_path_template, "**/main.sms.yml")
  rules_off            = (length(var.rules_off) > 0 ? join(" ", [for rule in var.rules_off : format("%s=off", rule)]) : "")
  rules_off_str        = (local.rules_off == "" ? "" : "rules=\"$(jo -p ${local.rules_off})\"")

  map_replace = jsonencode(var.map_replace)
  command_html_validate = replace(<<-BASH
    HTML_VALIDATE=$(jo -p \
          extends="$(jo -a html-validate:recommended)" ${local.rules_off_str}
    )
    echo $HTML_VALIDATE > .htmlvalidate.json
    html-validate --config .htmlvalidate.json $INDEX_HTML
  BASH
  , "\r", "")
  command_replace = replace(<<-BASH
    echo -ne "\e[42m[INFO]\e[0m BEGIN REPLACE IN $INDEX_HTML\e[0m\n"
      KEYS=$(echo $JSON | jq -r keys[])
      for KEY in $KEYS; do
        VALUE=$(echo $JSON | jq -r .$KEY)
        echo -ne "\e[42m[INFO]\e[0m Replacing $KEY --> $VALUE \e[0m\n"
        sed -ie "s|{$KEY}|$VALUE|g" $INDEX_HTML
        rm -f "$INDEX_HTML"e
      done
      echo -ne "\e[42m[INFO]\e[0m END REPLACE IN $INDEX_HTML\e[0m\n"
    BASH
  , "\r", "")
  command_html_minifier = replace(<<-BASH
      echo -ne "\e[42m[INFO]\e[0mHTML MINIFIER IN HTML \e[0m\n"
      python3<<PYTHON
      import htmlmin
      import os
      html_path = os.environ.get("INDEX_HTML")
      with open(html_path, "r") as f:
          minified_html = htmlmin.minify(f.read(), remove_all_empty_space=True,
                                          remove_comments=True,
                                          reduce_empty_attributes=True,
                                          remove_optional_attribute_quotes=False,
                                          convert_charrefs=True
                                          )
          minified_html = minified_html.replace("\n", "").replace("\t", "").replace("\r", "").replace("  ", " ").replace('"', "'")
      with open(html_path, "w") as f:
          f.write(minified_html)
      PYTHON
    BASH
    , "\r", ""
  )
  command_html_pinpoint_create_or_update = replace(<<-BASH
      echo -ne "\e[42m[INFO]\e[0m INICIO EMAIL TEMPLATE PINPOINT IN $INDEX_HTML\e[0m\n"
      NAME=$(yq eval '.name' $MAIN_YML)
      if [ -z "$NAME" ] || [ "$NAME" == "null" ]; then
        echo -ne "\e[41m[ERROR]\e[0mNAME is empty or null --> $NAME \e[0m\n"
        exit 1
      fi
      SUBJECT=$(yq eval '.subject' $MAIN_YML)
      if [ -z "$SUBJECT" ] || [ "$SUBJECT" == "null" ]; then
        echo -ne "\e[41m[ERROR]\e[0mSUBJECT is empty or null --> $SUBJECT \e[0m\n"
        exit 1
      fi
      echo -ne "\e[42m[INFO]\e[0mNAME --> $NAME \e[0m\n"
      echo -ne "\e[42m[INFO]\e[0mSUBJECT --> $SUBJECT \e[0m\n"
      
      export NAME=$NAME
      export SUBJECT=$SUBJECT
      python3<<PYTHON
      import boto3
      import os
      import json
      import logging

      pinpoint = boto3.client('pinpoint')

      def template_exists(name):
        try:
          response = pinpoint.get_email_template(
            TemplateName=name
          )
          return True
        except:
          return False

      def create_or_update(name, subject, html_path):
        print(json.dumps({'TemplateName': name, 'Subject': subject,  "HtnlPath": html_path}, indent=4, sort_keys=True, default=str))
        EmailTemplateRequest={
              'Subject': subject,
              'HtmlPart': open(html_path, "r").read()
        }
        if template_exists(name):
          print("Updating template: " + name)
          logging.info("Creating or updating template: " + name)
          response = pinpoint.update_email_template(
            TemplateName=name,
            EmailTemplateRequest=EmailTemplateRequest
          )
        else:
          print("Creating template: " + name)
          response = pinpoint.create_email_template(
            TemplateName=name,
            EmailTemplateRequest=EmailTemplateRequest
          )
          return response
      
      response = create_or_update(os.environ.get("NAME"), os.environ.get("SUBJECT"), os.environ.get("INDEX_HTML"))
      print(json.dumps(response, indent=4, sort_keys=True, default=str))
      PYTHON
    BASH
  , "\r", "")
  command_push_pinpoint_create_or_update = replace(<<-BASH
      echo -ne "\e[42m[INFO]\e[0m INICIO PUSH TEMPLATE PINPOINT IN $MAIN_YML\e[0m\n"
      NAME=$(yq eval '.name' $MAIN_YML)
      if [ -z "$NAME" ] || [ "$NAME" == "null" ]; then
        echo -ne "\e[41m[ERROR]\e[0mNAME is empty or null --> $NAME \e[0m\n"
        exit 1
      fi
      SUBJECT=$(yq eval '.subject' $MAIN_YML)
      if [ -z "$SUBJECT" ] || [ "$SUBJECT" == "null" ]; then
        echo -ne "\e[41m[ERROR]\e[0mSUBJECT is empty or null --> $SUBJECT \e[0m\n"
        exit 1
      fi
      BODY=$(yq eval '.body' $MAIN_YML)
      if [ -z "$BODY" ] || [ "$BODY" == "null" ]; then
        echo -ne "\e[41m[ERROR]\e[0mBODY is empty or null --> $BODY \e[0m\n"
        exit 1
      fi
      
      echo -ne "\e[42m[INFO]\e[0mNAME --> $NAME \e[0m\n"
      echo -ne "\e[42m[INFO]\e[0mSUBJECT --> $SUBJECT \e[0m\n"
      echo -ne "\e[42m[INFO]\e[0mBODY --> $BODY \e[0m\n"

      export NAME=$NAME
      export SUBJECT=$SUBJECT
      export BODY=$BODY
      python3<<PYTHON
      import boto3
      import os
      import json
      import yaml

      pinpoint = boto3.client('pinpoint')

      yaml_data = yaml.full_load(open(os.environ.get("MAIN_YML"), encoding="utf8"))

      subject = yaml_data['subject']
      name = yaml_data['name']
      body = yaml_data['body']


      def template_exists(name):
          try:
              response = pinpoint.get_push_template(
                  TemplateName=name
              )
              return True
          except:
              return False

      def create_or_update(name, title, body):
          PushNotificationTemplateRequest = {
              'Default': {
                  'Action': 'OPEN_APP',
                  'Body': body,
                  'Title': title,
              }
          }
          print(json.dumps(PushNotificationTemplateRequest, indent=4, sort_keys=True, default=str))
          if(template_exists(name)):
              response = pinpoint.update_push_template(
                  TemplateName=name,
                  PushNotificationTemplateRequest=PushNotificationTemplateRequest
              )
          else:
              response = pinpoint.create_push_template(
                  TemplateName=name,
                  PushNotificationTemplateRequest=PushNotificationTemplateRequest
              )
          return response

      response = create_or_update(name, subject, body)
      print(json.dumps(response, indent=4, sort_keys=True, default=str))
      PYTHON
    BASH
    , "\r", ""
  )
  command_sms_pinpoint_create_or_update = replace(<<-BASH
      echo -ne "\e[42m[INFO]\e[0m INICIO SMS TEMPLATE PINPOINT IN $MAIN_YML\e[0m\n"
      NAME=$(yq eval '.name' $MAIN_YML)
      if [ -z "$NAME" ] || [ "$NAME" == "null" ]; then
        echo -ne "\e[41m[ERROR]\e[0mNAME is empty or null --> $NAME \e[0m\n"
        exit 1
      fi
      BODY=$(yq eval '.body' $MAIN_YML)
      if [ -z "$BODY" ] || [ "$BODY" == "null" ]; then
        echo -ne "\e[41m[ERROR]\e[0mBODY is empty or null --> $BODY \e[0m\n"
        exit 1
      fi

      echo -ne "\e[42m[INFO]\e[0mNAME --> $NAME \e[0m\n"
      echo -ne "\e[42m[INFO]\e[0mBODY --> $BODY \e[0m\n"
      export NAME=$NAME
      export BODY=$BODY
      python3<<PYTHON
      import boto3
      import os
      import json
      import yaml

      pinpoint = boto3.client('pinpoint')
      yaml_data = yaml.full_load(open(os.environ.get("MAIN_YML"), encoding="utf8"))
      name = yaml_data['name']
      body = yaml_data['body']

      # sms
      def template_exists(name):
          try:
              response = pinpoint.get_sms_template(
                  TemplateName=name
              )
              return True
          except:
              return False

      def create_or_update(name, body):
          SMSTemplateRequest = {
              'Body': body
          }
          if template_exists(name):
              response = pinpoint.update_sms_template(
                  SMSTemplateRequest=SMSTemplateRequest,
                  TemplateName=name
              )
          else:
              response = pinpoint.create_sms_template(
                  SMSTemplateRequest=SMSTemplateRequest,
                  TemplateName=name
              )
          return response

      response = create_or_update(name, body)
      print(json.dumps(response, indent=4, sort_keys=True, default=str))
      PYTHON
    BASH
  , "\r", "")
}

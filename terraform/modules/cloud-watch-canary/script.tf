locals {
  file_content = file(var.script_path)
  zip          = "builds/${var.name}-${sha256(local.file_content)}.zip"
}

data "archive_file" "canary_script" {
  type        = "zip"
  output_path = local.zip
  source {
    content  = local.file_content
    filename = "nodejs/node_modules/index.js"
  }
}
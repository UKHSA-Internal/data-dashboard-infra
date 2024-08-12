locals {
  script_content      = file("../../src/${var.src_script_path}/index.js")
  script_content_hash = sha256(local.script_content)
  zip                 = "builds/${var.src_script_path}-${local.script_content_hash}.zip"
}

data "archive_file" "canary_script" {
  type        = "zip"
  output_path = local.zip
  source {
    content  = local.script_content
    filename = "nodejs/node_modules/index.js"
  }
}

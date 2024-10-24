locals {
  script_content      = file("${var.script_path}/index.js")
  script_content_hash = sha256(local.script_content)
}

data "archive_file" "canary_script" {
  type        = "zip"
  output_path = "builds/${var.name}-${local.script_content_hash}.zip"
  source {
    content  = local.script_content
    filename = "nodejs/node_modules/index.js"
  }
}

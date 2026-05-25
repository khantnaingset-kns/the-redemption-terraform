#!/usr/bin/env bash
set -euo pipefail

terraform-docs markdown table \
  --recursive \
  --recursive-path modules \
  --recursive-include-main=false \
  --output-file README.md \
  --output-mode inject \
  --output-template $'<!-- BEGIN_TF_DOCS -->\n## Terraform Modules Docs\n\n{{ .Content }}\n<!-- END_TF_DOCS -->' \
  .

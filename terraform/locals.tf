locals {
  name = "${var.project}-${var.environment}"
  timestamp = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
  private_subnet_id = split(",", data.aws_ssm_parameter.private_subnet_ids.value)[0]
}
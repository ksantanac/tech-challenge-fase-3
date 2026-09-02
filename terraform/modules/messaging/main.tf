resource "aws_sqs_queue" "events" {
  name                       = "${var.project}-events"
  message_retention_seconds  = 345600 # 4 dias
  visibility_timeout_seconds = 30
  tags                       = { Name = "${var.project}-events" }
}

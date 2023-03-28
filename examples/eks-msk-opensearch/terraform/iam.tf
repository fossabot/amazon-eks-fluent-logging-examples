################################################################################
# Logging Policy
################################################################################

resource "aws_iam_policy" "logging" {
  name_prefix = "Logging_IRSA_Policy-"
  description = "Logging IRSA Policy"
  policy      = templatefile("${path.module}/iam_policies/logging.json", { kafka_arn = module.kafka.cluster_arn})
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "logging" {
  role       = module.logging_irsa.iam_role_name
  policy_arn = aws_iam_policy.logging.arn
}

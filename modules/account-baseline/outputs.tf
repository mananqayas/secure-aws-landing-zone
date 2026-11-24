output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "The AWS Account ID where AWS Config was deployed"
}

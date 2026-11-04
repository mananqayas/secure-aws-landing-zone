output "ou_ids" {
  value       = { for k, v in aws_organizations_organizational_unit.this : k => v.id }
  description = "Map of OU keys to their AWS IDs"
}
output "account_ids" {
  value       = { for k, v in aws_organizations_account.this : k => v.id }
  description = "Map of Account keys to their Account Account IDs"
}

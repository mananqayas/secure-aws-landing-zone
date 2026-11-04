output "final_ou_inventory" {
  value       = module.aws_organization.ou_ids
  description = "Global OU ID registry displayed on terminal output"
}

output "final_account_ids" {

  value       = module.aws_organization.account_ids
  description = "Accounts id registry displayed on terminal output"
}

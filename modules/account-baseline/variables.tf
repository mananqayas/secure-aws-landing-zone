variable "management_account_id" {
  type        = string
  description = "Management account id"
}
variable "enable_config_aggregator" {
  type        = bool
  description = "Config aggregator iam:PassRole flag"
  default     = false
}

variable "is_audit_account" {
  type        = bool
  description = "Flag for audit account SLR statement grants"
  default     = false
}

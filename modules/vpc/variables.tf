variable "name" {
  type        = string
  description = "VPC name"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block address"
}

variable "enable_nat_gateway" {
  type        = string
  description = "Default gateway flag"
  default     = false
}

variable "flow_log_bucket_arn" {
  type        = string
  description = "Log archive bucket arn"
}

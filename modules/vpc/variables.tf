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

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones names"
}
variable "public_nacl_rules" {
  type = map(object({
    rule_number = number,
    egress      = bool,
    rule_action = string,
    protocol    = string,
    cidr_block  = string,
    from_port   = number,
    to_port     = number
  }))
  description = "Tier NACL map"
}
variable "private_nacl_rules" {
  type = map(object({
    rule_number = number,
    egress      = bool,
    rule_action = string,
    protocol    = string,
    cidr_block  = string,
    from_port   = number,
    to_port     = number
  }))
  description = "Tier NACL map"
}

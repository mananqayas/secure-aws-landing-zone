variable "organizational_units" {
  type = map(object({
    name = string
  }))
  description = "Map of Organizational Units to create"
  default     = {}

}

variable "accounts" {
  type = map(object({
    name              = string
    email             = string
    ou_key            = string
    close_on_deletion = bool
  }))
  description = "Map of AWS Accounts to create"
  default     = {}
}

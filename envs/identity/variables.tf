variable "groups" {
  type = map(object({ display_name = string
    description = string
  }))
  description = "Identity store group names"
}

variable "users" {
  type = map(object({
    display_name = string
    user_name    = string
    groups = list(string)
  }))
}

# FortiCNP provider variables
variable "forticnp_tokens" {
  default = null
}

# Lacework Agent data
variable "lacework_agent" {
  type    = map(string)
  default = {}
}

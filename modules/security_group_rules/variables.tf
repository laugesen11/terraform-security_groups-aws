#Declare variables to assign rules to security groups

variable "security_group_id" {
  description = "The ID of the security group these rules will apply to"
  type = string
}

variable "security_group_rules" {
  description = "The rules being applied to this security group ID"
  #This map is expected to have the values below:
  #"<key: description of rule>" => {
  #  "type"=                    = "egress|ingress"
  #  "description"              = "<optional description string>"
  #  "from_port"                = number
  #  "to_port"                  = number
  #  "protocol"                 = "<internet protocol>"
  #  "cidr_blocks"              = "<string of comma separated values of IPv4 CIDR blocks. Will split on comma>"
  #  "ipv6_cidr_blocks"         = "<string of comma separated values of IPv6 CIDR blocks. Will split on comma>"
  #  "prefix_list_ids"          = "<string of comma separated values of prefix list. Will split on comma>"
  #  "self"                     = bool (makes security group reference self). Set to null to turn off
  #  "source_security_group_id" = "<string of security group ID>"
  #}
  type        = map(string)
}

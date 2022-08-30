#Declare variables to assign rules to security groups

variable "security_group_id" {
  description = "The ID of the security group these rules will apply to"
  type = string
}

variable "security_group_rules" {
  description = "The rules being applied to this security group ID"
  #This map is expected to have the values below:
  #"<key: description of rule>" => {
  #  "type"                     = "egress|ingress"
  #  "from_port"                = number
  #  "to_port"                  = number
  #  "protocol"                 = "<internet protocol>"
  #  "cidr_blocks"              = list(<IPv4 CIDR blocks>)
  #  "ipv6_cidr_blocks"         = list(<IPv6 CIDR blocks>)
  #  "prefix_list_ids"          = list(<prefix list IDs>)
  #  "self"                     = bool (makes security group reference self)
  #  "source_security_group_id" = "<string of security group ID>"
  #}
  type        = map
}

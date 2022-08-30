#Declare variables to create security groups and their respective rules

variable "security_groups" {
  description = "Security groups high level setup"
  default = null
  
  type = list(
    object({ 
      #Must define the name, use this value for identification in configuration
      #This value will NOT be used to name security group if you set value for 'name_prefix'
      name                   = string
      vpc                    = string
      #Sets optional values. Expected values:
      #  #Sets the name prefix. Otherwise, security group name is set using 'name' value
      #  "name_prefix=<string>"
      #  #Makes it so rules are revoked on deletion
      #  "revoke_rules_on_delete"
      options                = list(string)
      tags                   = map(string)
      rules                  = list(
        object({ 
          is_egress                   = bool
          #Make a list with the to_port and from_port values
          #expected value: list(<from_port>,<to_port>)
          to_from_ports               = list(number)
          protocol                    = string

          #variable 'source_type' can be set to the below values:
          #  - ipv4            - specify a IPv4 CIDR Block
          #  - ipv6            - specify a IPv6 CIDR Block
          #  - prefix_list_ids - specify a comma separated list of prefix list IDs
          #  - self            - use security group ID this rule is assigned to as a source for the ingress rule
          #  - security_group  - use the name of a security group created in this module or and external security group ID as the source
          source_type = string

          #Source value can only be set to null if 'source_type' is set to 'self'
          source_value = string
        })
      )
    })
  )
}

variable "vpcs" {
  description = "The VPCs that we can resolve VPC names to"
  default = {}
  type = map
}

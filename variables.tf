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
      #  - "name_prefix"="<string>" - Sets the name prefix. Otherwise, security group name is set using 'name' value
      #  - "description"="<string>" - optional description
      #  - "revoke_rules_on_delete"=<true|false> - Makes it so rules are revoked on deletion
      #  - tags="<tag_name1>=<tag_value1>,<tag_name2>=<tag_value2>,..."
      options                = map(string)

      #Sets the options for rules
      #  - "is_egress"=<true|false> - sets the rule to be egress. Is ingress by default
      #  - "description"="<string>" - optional description
      # The below settings need to be put in place to ensure the correct traffic type is specified
      # Specifying a "traffic_type" will resolve the protocol and port range (from_port,to_port)
      # Leave this undefined and specify the protocol and ports yourself if you have a custom setup in mind
      #  - "traffic_type"=<string> - sets the traffic to a set of predefined values.
      #  - "protocol"=<protocol name or number> - set to icmp, icmpv6, tcp, udp, all, or the protocol number
      #  - "port"=<port number> - sets the port number if we only want to use one. Will set from_port and to_port to be equal
      #  - "from_port"=<beginning of port range> - lower bound of port range. Will set to same as "to_port" if not set
      #  - "to_port"=<end of port range> - upper bound of port range. Will set to same as "from_port" if not set
      # Only use these values if you set the protocol to icmp or icmpv6. Otherwise these are ignore
      #  - "icmp_type"=<ICMP type number> - sets the icmp type if the protcol is set to icmp
      #  - "icmp_code"=<ICMP code> - sets the icmp code if the protcol is set to icmp
      # Settings for the external traffic this rule is allowing
      # NOTE: remember, security groups can only ALLOW traffic, they cannot deny it
      # "cidr_blocks","ipv6_cidr_blocks", and "prefix_list_ids" can all be used together
      #  - "cidr_blocks"=<comma separated list of IPv4 CIDR blocks> 
      #  - "ipv6_cidr_blocks"=<comma separated list of IPv4 CIDR blocks> 
      #  - "prefix_list_ids"=<comma separated list of prefix list ids> 
      # WARNING: "security_groups" will cause "cidr_blocks","ipv6_cidr_blocks", and "prefix_list_ids" to be ignore. 
      #  - "security_groups"=<comma separated values of security group names or IDs> - can use security group names from this module
      # WARNING:"self" can only be used alone. Setting this will ignore "security_groups", "cidr_blocks","ipv6_cidr_blocks", and "prefix_list_ids"
      #  - "self"=<true|false> - uses this security group as the entity allowed access
      rules                  = list(map(string))
    })
  )
}

variable "vpcs" {
  description = "The VPCs that we can resolve VPC names to"
  default = {}
  type = map
}

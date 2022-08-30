security_groups = [
  {
    name                   = "sample security group 1"
    vpc                    = "vpc-0be76c384940e4bfc"
    options                = ["name_prefix=sample","revoke_rules_on_delete"]
    tags                   = {"Type" = "Sample"}
 
    rules  = [
      {
        is_egress       = true
        to_from_ports   = [0,0]
        protocol        = "all"
        source_type     = "self"
        source_value    = null
      },
      {
        is_egress       = false
        to_from_ports   = [0,0]
        protocol        = "all"
        source_type     = "self"
        source_value    = null
      },
    ]
  }
]

security_group_rules = [
  {
    security_group  = "sample security group 1"
    is_egress       = true
    to_from_ports   = [0,0]
    protocol        = "all"
    source_type     = "self"
    source_value    = null
  },
]

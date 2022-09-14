security_groups = [
  {
    name    = "sample security group 1"
    vpc     = "vpc-0be76c384940e4bfc"
    options = {"name_prefix"="sample","revoke_rules_on_delete"="true","tags"="Type=Sample"}
 
    rules  = [
      {
        is_egress = true ,
        traffic_type="all", 
        self=true 
      },
      {
        traffic_type="ssh" 
        cidr_blocks = "0.0.0.0/0"
        ipv6_cidr_blocks = "::/0"
      },
      {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_group = "sample security group 2"
      },
      {
        protocol = "icmp"
        icmp_code = 0
        icmp_type = 0
        cidr_blocks = "0.0.0.0/0"
      },
    ]
  },
  {
    name    = "sample security group 2"
    vpc     = "vpc-0be76c384940e4bfc"
    options = {"tags"="Type=For testing"}

    rules = []
  },
  
]


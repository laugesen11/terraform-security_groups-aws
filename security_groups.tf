#Creates seucrity groups and sets up input for security group rules module

#Typical traffic types we like to set security groups for
#These will be used with the "traffic_type" selection
locals{
  traffic_types = {
    "all" = {
      "to_port"   = 0
      "from_port" = 0
      "protocol"  = "all"
    }

    "http" = {
      "to_port"   = 80
      "from_port" = 80
      "protocol"  = "tcp"
    }

    "https" = {
      "to_port"   = 443
      "from_port" = 443
      "protocol"  = "tcp"
    }

    "ftp" = {
      "to_port"   = 21
      "from_port" = 21
      "protocol"  = "tcp"
    }

    "ssh" = {
      "to_port"   = 22
      "from_port" = 22
      "protocol"  = "tcp"
    }

    "telnet" = {
      "to_port"   = 23
      "from_port" = 23
      "protocol"  = "tcp"
    }

    "smtp" = {
      "to_port"   = 25
      "from_port" = 25
      "protocol"  = "tcp"
    }

    "web site response" = {
      "to_port"   = 1024
      "from_port" = 65535
      "protocol"  = "tcp"
    }

  }
  
  #Top level configuration for security group
  security_group_config = {
    for item in var.security_groups: 
      item.name => {
        "name"                   = item.name
        "vpc_id"                 = lookup(var.vpcs,item.vpc,null) != null ? var.vpcs[item.vpc].vpc.id : item.vpc
        "revoke_rules_on_delete" = lookup(item.options,"revoke_rules_on_delete","false") 
        "name_prefix"            = lookup(item.options,"name_prefix",null)
        "description"            = lookup(item.options,"description","Security group named ${item.name} for VPC ${item.vpc}")
        "tags"                   = lookup(item.options,"tags",null) == null ? {} : {
                                     for tag in split(",",item.options["tags"]):
                                       element(split("=",tag),0) => element(split("=",tag),1)
                                   }
      }
  }
}

#We first make all the security groups
#resource "aws_security_group" "security_groups"{
#  for_each               = local.security_group_config
#  #Set this to null if "name_prefix is defined"
#  name                   = each.value.name_prefix == null ? each.key : null
#  name_prefix            = each.value.name_prefix
#  vpc_id                 = each.value.vpc_id
#  revoke_rules_on_delete = each.value.revoke_rules_on_delete
#  description            = each.value.description
#  tags                   = merge({"Name" = each.key}, each.value.tags)
#}


#Sets up the rules for each security group based on list of 'rules' objects in 'security_groups' variable
#We create map from these values to use as inputs to the 'security_groups_rules' module
locals{
  security_group_rules_config = {
    for item in var.security_groups: 
      item.name => {
        for rule in item.rules:
          format("egress=%s rule %d for security group %s ",lookup(rule,"is_egress","false"),index(item.rules,rule),item.name) => {
            "type"        = lookup(rule,"is_egress",null) == "true" ? "egress" : "ingress" 
            "description" = lookup(rule,"description",null)

            #If we set a traffic_type, we set from_port to those values. If not, we check if the protocol is icmp; if yes, we set this to the ICMP type, if no, we set it to from_port
            "protocol"  = lookup(rule,"traffic_type",null) != null ? local.traffic_types[rule["traffic_type"]]["protocol"] : rule["protocol"]
            "from_port" = lookup(rule,"traffic_type",null) != null ? local.traffic_types[rule["traffic_type"]]["from_port"] : (lower(rule["protocol"]) == "icmp" ? rule["icmp_type"] : (lookup(rule,"port",null) != null ? rule["port"] : rule["from_port"] ))

            #If we set a traffic_type, we set to_port to those values. If not, we check if the protocol is icmp; if yes, we set this to the ICMP code, if no, we set it to "port" if defined, if not, we set to "to_port"
            "to_port" = lookup(rule,"traffic_type",null) != null ? local.traffic_types[rule["traffic_type"]]["to_port"] : (lower(rule["protocol"]) == "icmp" ? rule["icmp_code"] : (lookup(rule,"port",null) != null ? rule["port"] : rule["to_port"] ))
 
            #External sources settings
            #Sets to allow access from this security group. Overrides all other settings
            "self"              = lookup(rule,"self",null) 
            #Sets the list of IPv4 addresses we allow access to. Ignored if "security_groups" or self is set
            "cidr_blocks"       = lookup(rule,"self","false") == "true" || lookup(rule,"security_groups",null) != null ? null : lookup(rule,"cidr_blocks",null) 

            #Sets the list of IPv6 addresses we allow access to. Ignored if "security_groups" or self is set
            "ipv6_cidr_blocks"  = lookup(rule,"self","false") == "true" || lookup(rule,"security_groups",null) != null ? null : lookup(rule,"ipv6_cidr_blocks",null) 

            #Sets the list of prefix list ids we allow access to. Ignored if "security_groups" or self is set
            "prefix_list_ids"   = lookup(rule,"self","false") == "true" || lookup(rule,"security_groups",null) != null ? null : lookup(rule,"prefix_list_ids",null) 

            #If we specify "security_groups" option, we check and see if the security group value is the name of a security groups defined here
            #If not, we assume this is the external ID of a security group
            #Ignored if "self" is set
            #"source_security_group_id" = lookup(rule,"self","false") == "true" ? null : ( lookup(rule,"security_group",null) == null ? null : lookup(aws_security_group.security_groups,rule["security_group"],null) != null ? aws_security_group.security_groups[rule["security_group"]].id : rule["security_group"] )
            "source_security_group_id" = lookup(rule,"self","false") == "true" ? null : ( lookup(rule,"security_group",null) == null ? null : rule["security_group"] )
            
          }
      }
  }
}

resource "aws_security_group" "security_groups"{
  for_each               = local.security_group_config
  #Set this to null if "name_prefix is defined"
  name                   = each.value.name_prefix == null ? each.key : null
  name_prefix            = each.value.name_prefix
  vpc_id                 = each.value.vpc_id
  revoke_rules_on_delete = each.value.revoke_rules_on_delete
  description            = each.value.description
  tags                   = merge({"Name" = each.key}, each.value.tags)

  dynamic ingress{
    for_each = { for name,value in local.security_group_rules_config: name => value if value.type == "ingress" }
    content{
      description              = ingress.value.description
      to_port                  = ingress.value.to_port
      from_port                = ingress.value.from_port
      protocol                 = ingress.value.protocol
      cidr_blocks              = ingress.value.cidr_blocks
      ipv6_cidr_blocks         = ingress.value.ipv6_cidr_blocks
      prefix_list_ids          = ingress.value.prefix_list_ids
      self                     = ingress.value.self
      source_security_group_id = ingress.value.source_security_group_id
    }
  }

  dynamic egress{
    for_each = { for name,value in local.security_group_rules_config: name => value if value.type == "egress" }
    content{
      description              = egress.value.description
      to_port                  = egress.value.to_port
      from_port                = egress.value.from_port
      protocol                 = egress.value.protocol
      cidr_blocks              = egress.value.cidr_blocks
      ipv6_cidr_blocks         = egress.value.ipv6_cidr_blocks
      prefix_list_ids          = egress.value.prefix_list_ids
      self                     = egress.value.self
      source_security_group_id = egress.value.source_security_group_id
    }
  }
}
#Applies the rules to each security group
#module "security_groups_rules"{
#  source                 = "./modules/security_group_rules"
#  for_each               = local.security_group_rules_config
#  security_group_id      = aws_security_group.security_groups[each.key].id
#  security_group_rules   = each.value
#}

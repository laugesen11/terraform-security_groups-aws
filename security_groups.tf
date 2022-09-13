#Put everthing together here.
#
#This is where we call our child modules 
#
#module "<name>" {
#  source = "<path to module>"
#  version = "<remote module version. Some reports don't use this>"
#  providers = "<provider configurations to pass to child>"
#  count = <number we want>
#  
#  #Create multiple instances with map or list
#  #example with map
#  for_each = {
#    <var1> = <val1>
#    <var2> = <val2>
#  }
#  #applying these values
#  <var1> = each.key
#  <var2> = each.value
#  
#  #example with list
#  for_each = toset( <input list> )
#  #How to apply
#  #each.value is exactly the same
#  var = each.key
#
#  #Can chain for_each between resources
#  for_each = <resource type>.<name of resource built with for_each>
#  #apply like below
#  <var1> = each.value.<parameter>
#
#  #create explicit dependancy between entire module and listed targets
#  depends_on = []
#}

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

resource "aws_security_group" "security_groups"{
  for_each               = local.security_group_config
  #Set this to null if "name_prefix is defined"
  name                   = each.value.name_prefix == null ? each.key : null
  name_prefix            = each.value.name_prefix
  vpc_id                 = each.value.vpc_id
  revoke_rules_on_delete = each.value.revoke_rules_on_delete
  description            = each.value.description
  tags                   = merge({"Name" = item.name}, each.value.tags)
}


#Sets up the rules for each security group based on list of 'rules' objects in 'security_groups' variable
#We create map from these values to use as inputs to the 'security_groups_rules' module
locals{
  security_group_rules_config = {
    for item in var.security_groups: 
      item.name => {
        for rule in item.rules:
          "egress=${rule.is_egress} ${rule.source_type} rule from port ${rule.to_from_ports[0]} to port ${rule.to_from_ports[1]} by protocol ${rule.protocol} for security group ${item.name}" => {
            "type"        = lookup(rule.rule_settings,"is_egress",null) == "true" ? "egress" : "ingress" 
            "description" = lookup(rule.rule_settings,"description",null)

            #If we set a traffic_type, we set from_port to those values. If not, we check if the protocol is icmp; if yes, we set this to the ICMP type, if no, we set it to from_port
            "protocol"  = lookup(rule.rule_settings,"traffic_type",null) != null ? local.traffic_types[rule.rule_settings["traffic_type"]]["protocol"] : rule.rule_settings["protocol"]
            "from_port" = lookup(rule.rule_settings,"traffic_type",null) != null ? local.traffic_types[rule.rule_settings["traffic_type"]]["from_port"] : (lower(rule.rule_settings["protocol"]) == "icmp" ? rule.rule_settings["icmp_type"] : (lookup(rule.rule_settings,"port",null) != null ? rule.rule_settings["port"] : rule.rule_settings["from_port"] ))

            #If we set a traffic_type, we set to_port to those values. If not, we check if the protocol is icmp; if yes, we set this to the ICMP code, if no, we set it to "port" if defined, if not, we set to "to_port"
            "to_port" = lookup(rule.rule_settings,"traffic_type",null) != null ? local.traffic_types[rule.rule_settings["traffic_type"]]["to_port"] : (lower(rule.rule_settings["protocol"]) == "icmp" ? rule.rule_settings["icmp_code"] : (lookup(rule.rule_settings,"port",null) != null ? rule.rule_settings["port"] : rule.rule_settings["to_port"] ))
 
            #External sources settings
            #Sets to allow access from this security group. Overrides all other settings
            "self"              = lookup(rule.rule_settings,"self","false") 
            #Sets the list of IPv4 addresses we allow access to. Ignored if "security_groups" or self is set
            "cidr_blocks"       = lookup(rule.rule_settings,"self","false") == "true" || lookup(rule.rule_settings,"security_groups",null) != null ? null : ( lookup(rule.rule_settings,"cidr_blocks",null) == null ? null : tolist(split(",",rule.rule_settings["cidr_blocks"])) )
            #Sets the list of IPv6 addresses we allow access to. Ignored if "security_groups" or self is set
            "ipv6_cidr_blocks"  = lookup(rule.rule_settings,"self","false") == "true" || lookup(rule.rule_settings,"security_groups",null) != null ? null : ( lookup(rule.rule_settings,"ipv6_cidr_blocks",null) == null ? null : tolist(split(",",rule.rule_settings["ipv6_cidr_blocks"])) )
            #Sets the list of prefix list ids we allow access to. Ignored if "security_groups" or self is set
            "prefix_list_ids"   = lookup(rule.rule_settings,"self","false") == "true" || lookup(rule.rule_settings,"security_groups",null) != null ? null : ( lookup(rule.rule_settings,"prefix_list_ids",null) == null ? null : tolist(split(",",rule.rule_settings["prefix_list_ids"])) )

            #If we specify "security_groups" option, we check and see if the security group value is the name of a security groups defined here
            #If not, we assume this is the external ID of a security group
            "source_security_group_id" = lower(rule.source_type) != "security_group" ? null : (lookup(aws_security_group.security_groups,item.source_value,null) != null ? aws_security_group.security_groups[item.source_value].id : item.source_value) 
            "source_security_group_id" = lookup(rule.rule_settings,"self","false") == "true" ? null : ( lookup(rule.rule_settings,"security_groups",null) == null ? null : [
              for security_group in split(rule.rule_settings["security_groups"]):
                lookup(aws_security_group.security_groups,security_group,null) != null ? aws_security_group.security_groups[security_group].id : security_group
            ])
          }
      }
  }
}

module "security_groups_rules"{
  source                 = "./modules/security_group_rules"
  for_each               = local.security_group_rules_config
  security_group_id      = aws_security_group.security_groups[each.key].id
  security_group_rules   = local.security_group_rules_config[each.key]
}

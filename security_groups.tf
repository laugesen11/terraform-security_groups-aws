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
  #Gets any name prefixes set in the security groups
  security_group_name_prefixes = {
    for item in var.security_groups: 
      item.name => [
        #If the string matches "name_prefix=<string>", pull the value of <string>
        #WARNING: While this makes a list, we will only use the first value, so please do not set multiple values to prevent confusion
        for option in item.options: 
          chomp(trimspace(element(split("=",option),1))) if length(regexall("\\s*name_prefix\\s*=\\s*\\S",option)) > 0
      ]
  }
 
  security_group_config = {
    for item in var.security_groups: 
      item.name => {
        "name"                   = item.name
        "vpc_id"                 = lookup(var.vpcs,item.vpc,null) != null ? var.vpcs[item.vpc].vpc.id : item.vpc
        #Check the options input to see if it contains the string "revoke_rules_on_delete". If yes, set to true. If no, set to false
        "revoke_rules_on_delete" = item.options == null ? false : ( contains(item.options,"revoke_rules_on_delete") ? true : false )
        #Checks if there is a name_prefix for this security group 
        "name_prefix"            = length(local.security_group_name_prefixes[item.name]) == 0 ? null : local.security_group_name_prefixes[item.name][0]
        "tags"                   = merge({"Name" = item.name}, item.tags)
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
  description            = "Security group ${each.value.name_prefix} for VPC ${each.value.vpc_id}"
  tags                   = each.value.tags
}

#Sets up the rules for each security group based on list of 'rules' objects in 'security_groups' variable
#We create map from these values to use as inputs to the 'security_groups_rules' module
locals{
  security_group_rules_config = {
    for item in var.security_groups: 
      item.name => {
        for rule in item.rules:
          "egress=${rule.is_egress} ${rule.source_type} rule from port ${rule.to_from_ports[0]} to port ${rule.to_from_ports[1]} by protocol ${rule.protocol} for security group ${item.name}" => {
            "type"      = rule.is_egress ? "egress" : "ingress" 
            "from_port" = rule.to_from_ports[0]
            "to_port"   = rule.to_from_ports[1]
            "protocol"  = rule.protocol
            "cidr_blocks"       = lower(rule.source_type) == "ipv4" ? split(",",item.source_value) : null
            "ipv6_cidr_blocks"  = lower(rule.source_type) == "ipv6" ? split(",",item.source_value) : null
            "prefix_list_ids"   = lower(rule.source_type) == "prefix_list_ids" ? split(",",item.source_value) : null
            "self"              = lower(rule.source_type) == "self" ? true : false
            #If we specify "security_group" option, we check and see if the security group value is the name of a security groups defined here
            #If not, we assume this is the external ID of a security group
            "source_security_group_id" = lower(rule.source_type) != "security_group" ? null : (lookup(aws_security_group.security_groups,item.source_value,null) != null ? aws_security_group.security_groups[item.source_value].id : item.source_value) 
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

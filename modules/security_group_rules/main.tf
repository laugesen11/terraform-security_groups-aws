#Apply security group rules map to security group ID
resource "aws_security_group_rule" "security_group_rules" {
  for_each                 = var.security_group_rules
  security_group_id        = var.security_group_id
  type                     = each.value.type
  description              = each.value.description
  to_port                  = each.value.to_port
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
#  cidr_blocks              = each.value.cidr_blocks == null ? null : split(",",each.value.cidr_blocks)
#  ipv6_cidr_blocks         = each.value.ipv6_cidr_blocks == null ? null : split(",",each.value.ipv6_cidr_blocks) 
#  prefix_list_ids          = each.value.prefix_list_ids == null ? null : split(",",each.value.prefix_list_ids)
  cidr_blocks              = each.value.cidr_blocks 
  ipv6_cidr_blocks         = each.value.ipv6_cidr_blocks 
  prefix_list_ids          = each.value.prefix_list_ids 
  self                     = each.value.self
  source_security_group_id = each.value.source_security_group_id 
}

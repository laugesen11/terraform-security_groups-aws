output "security_groups" {
  description = "Map of security groups we created in this module"
  value       = aws_security_group.security_groups
}

output "security_group_rules" {
  description = "Map of security group rules assigned in this module"
  value       = module.security_groups_rules
}

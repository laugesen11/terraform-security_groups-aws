#Returns the security group rules for future use
output "security_group_rules" {
  description = "The security group rules created here" 
  value       = aws_security_group_rule.security_group_rules
}

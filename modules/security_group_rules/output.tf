#Set output values for this Terraform module. 
#Allows the root module to print outputs to CLI to confirm resource creation.
#Allows child module to expose a subset of its resource attributes to a parent module
#
#
#Example output:
#
#output "<name>" {
#  value = "<value we want to output>"
#  description = "<description>"
#  sensitive = "<should this show in standard output?>"
#
#  #Always include a comment on why this is needed. Use as last resort
#  depends_on = [<list of values that must be true>]
#
#  #Set a condition for the output to make sure the resource is set up correctly 
#  precondition {
#    condition     = "<value that must be true>"
#    error_message = "<message we output to screen>"
#  }
#}
output "security_group_rules" {
  description = "The security group rules created here" 
  value       = aws_security_group_rule.security_group_rules
}

Terraform template to create security groups:

- variable.tf                - Declares the variables for security groups and their rules, as well as input map for VPCs
- output.tf                  - Outputs security groups and rules
- security_groups.tf         - Creates security groups and applies rules
- security_group.auto.tfvars - file where we define default values for variables in variables.tf (top priority)

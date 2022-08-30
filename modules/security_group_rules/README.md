# Template to apply rules to security groups created in security group parent module 

- variable.tf                - declares variable for security group ID and rules
- ouput.tf                   - outputs the security group rules
- main.tf                    - Applies the input rules map to the security group ID

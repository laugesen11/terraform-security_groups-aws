Typical terraform template with best practices. Includes files below:

- variable.tf                - file for variable declaration
- ouput.tf                   - file for output configuration
- provider.tf                - file for provider configuration
- main.tf                    - file where we call our modules and bring everything together
- terraform.auto.tfvars      - file where we define default values for variables in variables.tf (top priority)
- terraform.auto.tfvars.json - file where we define default values for variables in variables.tf (top priority)
- terraform.tfvars.json      - file where we define default values for variables in variables.tf (second priority)
- terraform.tfvars           - file where we define default values for variables in variables.tf (third priority)

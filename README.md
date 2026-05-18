# Proxmox-Terraform

Terraform commands

#init
terraform init

#plan
terraform plan -var-file="credentials.auto.tfvars"

#apply
terraform apply -var-file="credentials.auto.tfvars"

#apply auto approve
terraform apply -var-file="credentials.auto.tfvars" -auto-approve

#save the plan
terraform plan -out="proxmox_plan" -var-file="credentials.auto.tfvars"

#apply the save plan
terraform apply "proxmox_plan"

#destroy
terraform destroy --auto-approve --var-file="credentials.auto.tfvars"

======================================================================
Folder Structure:

You have the following files:
credentials.auto.tfvars: This file contains your Proxmox API credentials. Since it's an .auto.tfvars file, Terraform automatically loads it without needing to specify it each time.
providers.tf: This file likely defines your provider configurations (in this case, Proxmox).
server.tf: This file defines the resources you want to manage, such as the Proxmox virtual machines.

How Terraform Knows What to Do:

Terraform reads all .tf files in the current directory. This means providers.tf and server.tf are both processed as part of the configuration.
The .tf files are processed together, and Terraform combines all the resources, variables, providers, and configurations specified in those files.

Breakdown:

providers.tf: This defines the Proxmox provider and the credentials, which are supplied via variables. It tells Terraform which platform you're interacting with (Proxmox in this case).

server.tf: This file likely contains the resource definitions, such as creating a VM   

credentials.auto.tfvars: This file contains the values for the variables (proxmox_api_url, proxmox_api_token_id, and proxmox_api_token_secret).

Summary:

When you run terraform plan or terraform apply, Terraform:

Loads all the .tf files (providers.tf, server.tf).
Automatically pulls in variables from credentials.auto.tfvars.
Combines everything into a plan and shows you what it will do (e.g., create a Proxmox VM).

So, Terraform knows what to do because it's reading and combining all the .tf files in the directory, along with the variable values from credentials.auto.tfvars.

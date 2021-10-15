.PHONY: init plan apply validate destroy format

init:
	aws-vault exec madetech-sandbox -- terraform init

plan:
	aws-vault exec madetech-sandbox -- terraform plan -var-file="../config/terraform/env.tfvars"

apply:
	aws-vault exec madetech-sandbox -- terraform apply -var-file="../config/terraform/env.tfvars" --auto-approve

destroy:
	aws-vault exec madetech-sandbox -- terraform destroy -var-file="../config/terraform/env.tfvars"

validate:
	aws-vault exec madetech-sandbox -- terraform validate

format:
	aws-vault exec madetech-sandbox -- terraform fmt

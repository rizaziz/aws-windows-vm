.PHONY: lint
lint:
	terraform init
	terraform fmt
	terraform validate

.PHONY: plan
plan:
	terraform plan -out infra.tfplan

.PHONY: apply
apply:
	terraform apply -auto-approve infra.tfplan

.PHONY: destroy
destroy:
	terraform destroy -auto-approve
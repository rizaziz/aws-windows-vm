VM_NAME := rhel9

TF_PLAN = terraform plan \
			-var="whitelisted_ip=$(shell curl -4 ifconfig.me)/32" \
			-var="vm_name=$(VM_NAME)" \
			-var="home_dir=$(shell echo $$HOME)" \
			-out tfplan $(EXTRA_OPTS)

.PHONY: init
init:
	terraform init

.PHONY: lint
lint:
	terraform validate && terraform fmt -recursive

.PHONY: plan
plan:
	$(TF_PLAN)

.PHONY: apply
apply:
	terraform apply tfplan

.PHONY: destroy
destroy: EXTRA_OPTS = -destroy
destroy:
	$(TF_PLAN)
	terraform apply tfplan

.PHONY: ssh
ssh:
	@echo "Connecting to the virtual machine via SSH..."
	@ssh $(VM_NAME)
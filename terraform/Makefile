DOCKER_IMG := terraform-dev
CURR_AMI := "ami=ami-0dfc569a8686b9320" #"ami=ami-0bbdd8c17ed981ef9" #"ami=ami-0b0012dad04fbe3d7" #"ami=ami-0dfc569a8686b9320" #"ami=ami-0fd3ac4abb734302a" #"ami=ami-00f1cb0e129bb040e" #"ami=ami-06cb8f36f00a2b90c"  # "ami=ami-02b60b5095d1e5227"
VM_NAME := rhel9

.PHONY: image
image:
	docker build -t $(DOCKER_IMG) .

.PHONY: init
init:
	@echo "Initializing Terraform..."
	terraform init

.PHONY: lint
lint:
	@echo "Linting Terraform files..."
	terraform fmt
	terraform validate

.PHONY: plan
plan:
	@echo "Planning Terraform changes..."
	terraform plan -var="whitelisted_ip=$(shell curl -s -4 ifconfig.me)/32" -var="vm-state=running" -var=$(CURR_AMI) -var=vm_name=$(VM_NAME) -out=tfplan

.PHONY: apply
apply:
	@echo "Applying Terraform changes..."
	terraform apply tfplan


.PHONY: taint
taint:
	@echo "Tainting the virtual machine..."
	terraform taint aws_instance.rhel[0]
	$(MAKE) plan
	$(MAKE) apply


.PHONY: destroy
destroy:
	@echo "Destroying Terraform resources..."
	terraform destroy -var="whitelisted_ip=$(shell curl -s -4 ifconfig.me)/32" -var="vm-state=stopped" -auto-approve

.PHONY: pwd
pwd:
	@terraform output -raw win_password
	@echo ""


.PHONY: rdp
rdp:	
	@echo "Connecting to the virtual machine via RDP..."
	powershell.exe -Command '$(shell terraform output -raw cmdkey)'
	powershell.exe -Command $(shell terraform output -raw rdp_command)
	
.PHONY: ssh
ssh:
	@echo "Connecting to the virtual machine via SSH..."
	$(shell if [ ! -d "~/.ssh" ]; then mkdir ~/.ssh 2>/dev/null; fi)
	@cp id_rsa ~/.ssh/id_rsa
	@chmod 600 ~/.ssh/id_rsa
	@cp config ~/.ssh/config
	@ssh $(VM_NAME)


.PHONY: vm-on
vm-on: plan apply
	@echo "Virtual machine is now running."

.PHONY:	vm-off
vm-off: 
	@echo "Stopping virtual machine..."
	terraform apply -var="vm-state=stopped" -var=$(CURR_AMI) -var=vm_name=$(VM_NAME) -auto-approve

.PHONY: list-win-images
list-win-images:
	aws ec2 describe-images \
		--region=us-east-1 \
		--owners amazon \
		--filters "Name=platform,Values=windows" "Name=name,Values=Windows_Server-2025-English-*-*-*" \
		--query "Images[*].[ImageId,Name,PlatformDetails]" \
		--output table

.PHONY: list-rhel-images
list-rhel-images:
	aws ec2 describe-images \
		--region=us-east-1 \
		--owners amazon \
		--filters "Name=platform-details,Values=Red Hat Enterprise Linux" "Name=architecture,Values=x86_64" "Name=name,Values=RHEL-9*HVM-2025*" \
		--query "Images[*].[ImageId,Name,PlatformDetails,Architecture]" \
		--output table

.PHONY: list-linux-images
list-linux-images:
	@echo "Amazon Linux 2:"; \
	aws ec2 describe-images \
		--region=us-east-1 \
		--owners amazon \
		--filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
		--query "Images[*].[ImageId,Name,CreationDate,OwnerId]" \
		--output table; \
	echo ""; \
	echo "Ubuntu:"; \
	aws ec2 describe-images \
		--region=us-east-1 \
		--owners amazon \
		--filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-*-*-amd64-server-*" \
		--query "Images[*].[ImageId,Name,CreationDate,OwnerId]" \
		--output table; \
	echo ""; \
	echo "Debian:"; \
	aws ec2 describe-images \
		--region=us-east-1 \
		--owners amazon \
		--filters "Name=name,Values=debian-*-amd64-*" \
		--query "Images[*].[ImageId,Name,CreationDate,OwnerId]" \
		--output table; \
	echo ""; \
	echo "CentOS:"; \
	aws ec2 describe-images \
		--region=us-east-1 \
		--owners amazon \
		--filters "Name=name,Values=CentOS-*-x86_64-*" \
		--query "Images[*].[ImageId,Name,CreationDate,OwnerId]" \
		--output table


# Bash select example: choose an option from a list
.PHONY: select
select:
	@bash -c 'select opt in Option1 Option2 Option3 Exit; do \
	  case $$opt in \
		Option1) echo "You chose Option1";; \
		Option2) echo "You chose Option2";; \
		Option3) echo "You chose Option3"; break;; \
		Exit) break;; \
		*) echo "Invalid option";; \
	  esac; \
	done'

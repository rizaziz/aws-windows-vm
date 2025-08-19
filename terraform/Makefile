DOCKER_IMG := terraform-dev
CURR_AMI := "ami=ami-00583753a2de7e452"

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
	terraform plan -var="whitelisted_ip=$(shell curl -s -4 ifconfig.me)/32" -var="vm-state=running" -var=$(CURR_AMI) -out=tfplan

.PHONY: apply
apply:
	@echo "Applying Terraform changes..."
	terraform apply tfplan


.PHONY: taint
taint:
	@echo "Tainting the virtual machine..."
	terraform taint aws_instance.dev
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
	@cp win_key ~/.ssh/win_key
	@chmod 600 ~/.ssh/win_key
	@cp config ~/.ssh/config
	@ssh win


# C:\Users\Aziz Rizayev\Workspace\mot.OS-UI\install-scripts\motosui\Product Configuration 1\Release 1\MsixPackage\motosui
.PHONY: scp
scp:
	@echo "Copying files to the virtual machine via SCP..."
	scp "$(shell realpath "$(shell pwd)/../../repos/mot.OS-UI/install-scripts/install-scripts.zip")" win:C:\

.PHONY: vm-on
vm-on: plan apply
	@echo "Virtual machine is now running."

.PHONY:	vm-off
vm-off: 
	@echo "Stopping virtual machine..."
	terraform apply -var="vm-state=stopped" -var=$(CURR_AMI) -auto-approve

.PHONY: list-win-images
list-win-images:
	aws ec2 describe-images \
		--region=us-east-1 \
		--owners amazon \
		--filters "Name=platform,Values=windows" "Name=name,Values=Windows_Server-2025-English-*-*-*" \
		--query "Images[*].[ImageId,Name,PlatformDetails]" \
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

DOCKER_IMG := dev-container
DOCKER_ADM_USER := admin
DOCKER_HOME := /home/$(DOCKER_ADM_USER)
DATA_VOLUME := dev-container-data


.PHONY: image
image:
	docker build \
		-t $(DOCKER_IMG) \
		--build-arg USR_ID=$(shell id -u) \
		--build-arg USR_NAME=$(shell id -un) \
		--build-arg GRP_ID=$(shell id -g) \
		--build-arg GRP_NAME=$(shell id -gn) \
		--build-arg DOCKER_GRP_ID=$(shell getent group docker | cut -d: -f3) \
		--build-arg ADM_USR_NAME=$(DOCKER_ADM_USER) \
		.

.PHONY: vols
vols:
	@echo "Creating docker volumes"
	docker volume create $(DATA_VOLUME)
	

.PHONY: shell
shell:
	docker run --rm -ti \
		-v $(CURDIR):$(CURDIR) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(DATA_VOLUME):$(DOCKER_HOME) \
		-v $(shell echo ~/Downloads):$(shell echo ~/Downloads) \
		-w $(CURDIR) \
		$(DOCKER_IMG) bash

.PHONY: prune
prune:
	docker volume rm --force $(DATA_VOLUME)
	$(MAKE) vols


.PHONY: pyenv
pyenv:
	docker run --rm -ti \
		-v $(DATA_VOLUME):$(DOCKER_HOME) \
		-v $(CURDIR)/pyenv.sh:/pyenv.sh \
		$(DOCKER_IMG) /pyenv.sh

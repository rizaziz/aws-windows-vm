DOCKER_IMG := dev-container
DOCKER_HOME_BIN_VOLUME := $(DOCKER_IMG)-home-bin


.PHONY: image
image:
	docker build \
		-t $(DOCKER_IMG) \
		--build-arg USR_ID=$(shell id -u) \
		--build-arg USR_NAME=$(shell id -un) \
		--build-arg GRP_ID=$(shell id -g) \
		--build-arg GRP_NAME=$(shell id -gn) \
		--build-arg DOCKER_GRP_ID=$(shell getent group docker | cut -d: -f3) \
		.

.PHONY: vols
vols:
	@echo "Creating docker volumes"
	docker volume create $(DOCKER_HOME_BIN_VOLUME)

.PHONY: shell
shell:
	docker run --rm -ti --group-add docker \
		-v $(CURDIR):$(CURDIR) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v dev-container-home-bin:/home/$(shell id -gn) \
		-w $(CURDIR) --name $(DOCKER_IMG) \
		$(DOCKER_IMG) bash

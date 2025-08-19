FROM debian:bullseye
RUN apt-get update && \
    apt-get install -y curl ca-certificates openssh-server sudo iputils-ping git make unzip

# Docker client tools
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install docker-ce-cli docker-buildx-plugin docker-compose-plugin

# Pyenv 
RUN curl -fsSL https://pyenv.run | bash

# Installing Terraform
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh | bash

ARG USR_ID=1000
ARG USR_NAME=admin
ARG GRP_ID=1000
ARG GRP_NAME=admin
ARG DOCKER_GRP_ID=1001
ARG USER_HOME=/home/${USR_NAME}

RUN echo "%sudo ALL = (ALL) NOPASSWD: ALL" > /etc/sudoers.d/pwdless

RUN groupadd --force --gid ${GRP_ID} ${GRP_NAME}
RUN groupadd --force --gid ${DOCKER_GRP_ID} docker
RUN useradd --uid ${USR_ID} --gid ${GRP_ID} --groups sudo --create-home --non-unique ${USR_NAME}

USER ${USR_NAME}

COPY bashrc ${USER_HOME}/.bashrc

WORKDIR /home/${USR_NAME}

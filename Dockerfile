FROM python:bullseye

RUN apt-get update && \
    apt-get install -y curl ca-certificates openssh-server sudo iputils-ping git make unzip build-essential less

# Docker client tools
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install docker-ce-cli docker-buildx-plugin docker-compose-plugin

# Installing Terraform
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh | bash

# Installing tflint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Installing AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install

# Installing GCP SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update -y && apt-get install google-cloud-cli -y
    

ARG USR_ID=1000
ARG USR_NAME=user
ARG GRP_ID=1000
ARG GRP_NAME=user
ARG DOCKER_GRP_ID=1001
ARG ADM_USR_NAME=admin
ARG ADM_USER_HOME=/home/${ADM_USR_NAME}

RUN echo "%sudo ALL = (ALL) NOPASSWD: ALL" > /etc/sudoers.d/pwdless

RUN groupadd --force --gid ${GRP_ID} ${ADM_USR_NAME}
RUN groupadd --force --gid ${DOCKER_GRP_ID} docker
# RUN useradd --uid ${USR_ID} --gid ${GRP_ID} --groups sudo,docker --create-home --non-unique ${USR_NAME}
RUN useradd --uid ${USR_ID} --gid ${GRP_ID} --groups sudo,docker --create-home --non-unique ${ADM_USR_NAME}

USER ${ADM_USR_NAME}

ENV PATH=${ADM_USER_HOME}/bin:$PATH
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
WORKDIR ${ADM_USER_HOME}

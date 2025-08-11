# Example Dockerfile
FROM python
RUN apt-get update && apt-get install -y curl openssh-server sudo iputils-ping git make unzip

# Installing Terraform
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh | bash


RUN useradd -m -s /bin/bash user
RUN echo "user:user" | chpasswd
RUN usermod -aG sudo user
EXPOSE 22
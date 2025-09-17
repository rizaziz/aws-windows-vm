FROM debian:bullseye

RUN apt update && apt install -y iproute2 iputils-ping net-tools curl less

RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh | bash
FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl wget gpg ca-certificates xsltproc git unzip

RUN useradd --create-home appuser

USER appuser
WORKDIR /home/appuser
COPY . .

CMD [ "tail", "-f", "/dev/null" ]

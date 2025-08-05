FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

COPY . /jira-markdown/
RUN apt-get update && \
    apt-get install -y curl wget gpg ca-certificates xsltproc git zip unzip vim xmlstarlet pandoc rclone

RUN useradd --create-home appuser

USER appuser
WORKDIR /home/appuser

CMD [ "tail", "-f", "/dev/null" ]

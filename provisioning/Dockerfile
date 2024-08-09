# syntax=docker/dockerfile:1.3

ARG CENTOS_STREAM9_IMAGE=quay.io/centos/centos:stream9

FROM ${CENTOS_STREAM9_IMAGE}

# configure valid UTF-8 locale
ENV \
  LANG=C \
  LC_CTYPE=en_US.UTF-8

RUN \
      dnf update -y \
  &&  dnf install -y epel-release \
  &&  dnf install -y \
        git \
        jq \
        openssh openssh-clients \
        python3 python3-pip \
        glibc-langpack-en \
  && dnf clean all

#  Ansible
ADD requirements.txt /tmp/

RUN \
      pip3 install -r /tmp/requirements.txt \
  &&  ansible --version && python3 -c 'import jinja2; print("jinja2: " + jinja2.__version__)'

ADD requirements.yml ansible-galaxy.sh /tmp/

ARG GITHUB_USERNAME

RUN --mount=type=secret,id=github-token \
      GITHUB_TOKEN_FILE=/run/secrets/github-token \
        /tmp/ansible-galaxy.sh collection install -p /usr/share/ansible/collections -r /tmp/requirements.yml \
  &&  ansible-galaxy collection list

# configure build user
ARG BUILD_UID
ARG BUILD_GID

RUN \
      echo "build:x:${BUILD_GID}:" >> /etc/group \
  &&  echo "build:*:${BUILD_UID}:${BUILD_GID}:Build:/home/build:/bin/sh" | newusers -c NONE

USER build
VOLUME /home/build

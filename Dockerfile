####################################################################################
# AWSH Container
###############################################################################
FROM alpine:3.7
MAINTAINER hugh.mooney@hest.io

###############################################################################
# ENVs
###############################################################################
ENV AWSH_ROOT /opt/awsh
ENV PYTHONPATH /opt/awsh/lib/python
ENV PATH /opt/awsh/bin:/opt/awsh/bin/tools:$PATH
ENV AWSH_PYTHON_DEPS /opt/awsh/requirements/requirements.python2
ENV AWSH_CONTAINER docker
ENV PATCHED_FONT_IN_USE no
ENV AWSH_VERSION_DOCKER latest

ENV RUNTIME_PACKAGES \
  bash \
  coreutils \
  curl \
  tar \
  openssh-client \
  sshpass \
  git \
  python \
  py-boto \
  py-dateutil \
  py-httplib2 \
  py-jinja2 \
  py-paramiko \
  py-pip \
  py-yaml \
  ncurses \
  util-linux \
  util-linux-bash-completion \
  jq \
  krb5 \
  ca-certificates

ENV HTTP_PROXY "${http_proxy}"
ENV http_proxy "${http_proxy}"
ENV HTTPS_PROXY "${https_proxy}"
ENV https_proxy "${https_proxy}"
ENV no_proxy "${no_proxy}"
ENV NO_PROXY "${NO_PROXY}"


###############################################################################
# ARGs
###############################################################################
ARG HTTP_PROXY="${http_proxy}"
ARG http_proxy="${http_proxy}"
ARG HTTPS_PROXY="${https_proxy}"
ARG https_proxy="${https_proxy}"
ARG no_proxy="${no_proxy}"
ARG NO_PROXY="${NO_PROXY}"

###############################################################################
# LABELs
###############################################################################

# Add our dummy user and group
RUN adduser -D -u 1000 awsh

RUN mkdir -p /opt/awsh
COPY / /opt/awsh

RUN \
    # update packages
    apk update && apk upgrade && \

    # install build support. needed for Kerberos installation
    apk --update add --virtual build-dependencies alpine-sdk gcc krb5-dev musl-dev libffi-dev openssl-dev python-dev && \

    # install AWSH runtime packages
    apk add --no-cache ${RUNTIME_PACKAGES} && \

    # install AWSH Python dependencies
    pip install -r ${AWSH_PYTHON_DEPS} --disable-pip-version-check && \

    # install ruby  (needed for terraforming tool)
    apk --no-cache add ruby ruby-dev ruby-bundler ruby-json ruby-irb ruby-rake ruby-bigdecimal && \

    # remove the build tools
    apk del build-dependencies && \

    # cleanup after installations
    rm -rf /var/cache/apk/*


RUN mkdir -p /opt/awsh/log /opt/awsh/tmp /home/awsh/.aws

RUN echo '. /opt/awsh/etc/awshrc' >> /home/awsh/.bashrc

# Build default AWS CLI config so that it doesn't have a brain fart when
# run due to not setting it's own sensible defaults
RUN echo '[default]' >> /home/awsh/.aws/config
RUN echo 'output = json' >> /home/awsh/.aws/config

RUN echo '[default]' >> /home/awsh/.aws/credentials
RUN echo 'aws_access_key_id = 1' >> /home/awsh/.aws/credentials
RUN echo 'aws_secret_access_key = 1' >> /home/awsh/.aws/credentials

RUN chown -R awsh: /opt/awsh
RUN chown -R awsh: /home/awsh

USER awsh

WORKDIR /home/awsh

ENTRYPOINT ["/bin/bash"]

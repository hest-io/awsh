###############################################################################
# AWSH Container - Vanilla AWSH Toolset
###############################################################################
FROM alpine:3.10

###############################################################################
# ARGs
###############################################################################
ARG HTTP_PROXY="${http_proxy}"
ARG http_proxy="${http_proxy}"
ARG HTTPS_PROXY="${https_proxy}"
ARG https_proxy="${https_proxy}"
ARG no_proxy="${no_proxy}"
ARG NO_PROXY="${NO_PROXY}"

ARG RUNTIME_PACKAGES="\
    bash \
    ca-certificates \
    coreutils \
    curl \
    git \
    graphviz \
    jq \
    krb5 \
    libc6-compat \
    ncurses \
    openssh-client \
    py-dateutil \
    py-httplib2 \
    py-paramiko \
    py-pip \
    python \
    shadow \
    sshpass \
    tar \
    util-linux \
    util-linux-bash-completion"

ARG RUBY_RUNTIME_PACKAGES="\
    ruby \
    ruby-bigdecimal \
    ruby-bundler \
    ruby-dev \
    ruby-irb \
    ruby-json \
    ruby-rake"

ARG SW_VER_TERRAFORMING="0.18.0"
ARG SW_VER_WEBRICK="1.6.0"
ARG SW_VER_FIXUID="0.4"

ARG AWSH_PYTHON_DEPS="/tmp/requirements.python2"

###############################################################################
# ENVs
###############################################################################
ENV AWSH_ROOT /opt/awsh
ENV AWSH_USER_HOME /home/awsh
ENV AWSH_USER awsh
ENV AWSH_GROUP awsh
ENV PUID 1000
ENV PGID 1000
ENV PYTHONPATH /opt/awsh/lib/python
ENV PATH /opt/awsh/bin:/opt/awsh/bin/tools:$PATH
ENV AWSH_CONTAINER docker
ENV PATCHED_FONT_IN_USE no
ENV AWSH_VERSION_DOCKER latest
ENV HTTP_PROXY "${http_proxy}"
ENV http_proxy "${http_proxy}"
ENV HTTPS_PROXY "${https_proxy}"
ENV https_proxy "${https_proxy}"
ENV no_proxy "${no_proxy}"
ENV NO_PROXY "${NO_PROXY}"

###############################################################################
# LABELs
###############################################################################

# Add our dummy user and group
RUN adduser -D -u ${PUID} ${AWSH_USER}

# AWSH and AWS CLI paths
RUN mkdir -p ${AWSH_USER_HOME}/.awsh/log ${AWSH_ROOT}/tmp ${AWSH_USER_HOME}/.aws
COPY requirements/requirements.python2 ${AWSH_PYTHON_DEPS}

RUN \
    # update packages
    apk update && apk upgrade && \
    # install build support. needed for Kerberos installation
    apk --update add --virtual build-dependencies alpine-sdk gcc krb5-dev musl-dev libffi-dev openssl-dev python-dev && \
    # install AWSH runtime packages
    apk --no-cache add ${RUNTIME_PACKAGES} && \
    # install AWSH Python dependencies
    python -m pip install -r ${AWSH_PYTHON_DEPS} --disable-pip-version-check && \
    # install ruby  (needed for terraforming tool)
    apk --no-cache add ${RUBY_RUNTIME_PACKAGES} && \
    # remove the build tools
    apk del build-dependencies && \
    # Add Terraforming Ruby tool
    gem install webrick --version ${SW_VER_WEBRICK} --no-ri --no-rdoc && \
    gem install terraforming --version ${SW_VER_TERRAFORMING} --no-ri --no-rdoc && \
    # cleanup after installations
    rm -rf /var/cache/apk/*

# Install fixuid
RUN \
    curl -SsL "https://github.com/boxboat/fixuid/releases/download/v${SW_VER_FIXUID}/fixuid-${SW_VER_FIXUID}-linux-amd64.tar.gz" | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid

# Build the config for fixuid
COPY /lib/docker/fixuid.yml /etc/fixuid/config.yml
  
# Add our code
COPY / ${AWSH_ROOT}

# Link the JQ module library
RUN ln -s ${AWSH_ROOT}/lib/jq ${AWSH_USER_HOME}/.jq

# Ensure the AWSH lib is being loaded into the shell
RUN echo '. /opt/awsh/etc/awshrc' >> ${AWSH_USER_HOME}/.bashrc

# Build default AWS CLI config so that it doesn't have a brain fart when
# run due to not setting it's own sensible defaults
RUN { \
    echo '[default]' ; \
    echo 'output = json' ; \
    } | tee ${AWSH_USER_HOME}/.aws/config

RUN { \
    echo '[default]' ; \
    echo 'aws_access_key_id = 1' ; \
    echo 'aws_secret_access_key = 1' ; \
    } | tee ${AWSH_USER_HOME}/.aws/credentials
    
# Ensure ownership of AWSH paths
RUN \
    chown -c -R ${AWSH_USER}:${AWSH_GROUP} ${AWSH_ROOT} && \
    chown -c -R ${AWSH_USER}:${AWSH_GROUP} ${AWSH_USER_HOME}

WORKDIR ${AWSH_USER_HOME}

ENTRYPOINT ["fixuid"]

CMD ["-q", "/bin/bash"]

USER ${AWSH_USER}:${AWSH_GROUP}

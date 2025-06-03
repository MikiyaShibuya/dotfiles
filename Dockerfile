ARG UBUNTU_CODENAME=noble

FROM ubuntu:${UBUNTU_CODENAME}

ARG GID
ARG UID
ARG USER
ARG PASS

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NOWARNINGS=yes \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    USER=$USER

RUN apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends \
      openssh-server locales-all sudo \
      > /dev/null && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    \
    # Add user and group \
    if [ "$(getent passwd $UID)" != "" ]; then \
      userdel -r "$(getent passwd $UID | awk -F: '{print $1}')"; \
    fi && \
    if [ -z "$(getent group $GID)" ]; then \
      groupadd -g $GID $USER; \
    fi && \
    if [ -z "$(getent passwd $USER)" ]; then \
      useradd -u $UID -g $GID -s /bin/zsh -m $USER && \
      echo $USER:$PASS | chpasswd && \
      adduser $USER sudo; \
    fi && \
    \
    # Make directory to copy this repository \
    mkdir -p /home/$USER/.local/share/dotfiles && \
    chown -R $USER:$USER /home/$USER/.local


COPY --chown=$UID:$GID . /home/$USER/.local/share/dotfiles

# Install preferences
WORKDIR /home/$USER/.local/share/dotfiles
RUN ./install.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY docker/entrypoint.sh /tmp/entrypoint.sh
CMD ["/tmp/entrypoint.sh"]


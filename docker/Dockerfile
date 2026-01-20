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

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends \
      openssh-server locales-all sudo \
      > /dev/null && \
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
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/home/$USER/.cache/pip,uid=$UID,gid=$GID \
    ./install.sh

COPY docker/entrypoint.sh /tmp/entrypoint.sh
CMD ["/tmp/entrypoint.sh"]


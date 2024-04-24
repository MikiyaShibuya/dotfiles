FROM --platform=amd64 ubuntu:22.04

ARG USER=docker

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y openssh-server zsh sudo locales-all \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# SSH server setup
RUN sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd


# User setting
ARG GID
ARG UID
ARG PASSWORD

RUN if [ -z "$(getent group $GID)" ]; then \
    groupadd -g $GID $USER; \
  fi \
  && if [ -z "$(getent passwd $USER)" ]; then \
    useradd -u $UID -g $GID -s /bin/zsh -m $USER \
    && echo $USER:password | chpasswd \
    && adduser shibuya sudo; \
  fi

# repository
RUN su $USER -c "mkdir /home/$USER/dotfiles"
COPY --chown=$UID:$GID . /home/$USER/dotfiles
WORKDIR /home/$USER/dotfiles

# Install preferences
RUN /home/$USER/dotfiles/install.sh \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV USER=$USER

COPY docker/entrypoint.sh /tmp/entrypoint.sh
CMD /tmp/entrypoint.sh


FROM ubuntu:20.04

ARG USER=docker

ENV DEBIAN_FRONTEND=noninteractive

# Install essential apt packages
RUN apt-get update \
  && apt-get install -y sudo git htop wget curl tmux zsh locales-all \
    software-properties-common python3-pip \
    libreadline-dev libffi-dev libncurses-dev \
    libssl-dev liblzma-dev libbz2-dev libsqlite3-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install neovim & node
RUN wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb \
  && apt-get install ./nvim-linux64.deb \
  && rm ./nvim-linux64.deb \
  && curl -fsSL https://deb.nodesource.com/setup_18.x -o /tmp/nodesource_setup.sh \
  && bash /tmp/nodesource_setup.sh \
  && apt-get install -y nodejs \
  && npm config set prefix '~/.local/' \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# === SSH server setup begin === \
# Enable ssh login into docker container \
# This requires same password as host OS \
RUN apt-get update \
  && apt-get install -y openssh-server \
  && sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
# === SSH server setup end === \
  && apt-get install -y libbz2-dev libsqlite3-dev zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


# User setting
ARG GID=1000
ARG UID=1000
RUN groupadd -g $GID $USER \
  && useradd -u $UID -g $GID -s /bin/zsh -m $USER \
  && su $USER -c "mkdir /home/$USER/dotfiles"

USER $USER

# SSH key setting
WORKDIR /home/$USER/.ssh
RUN ssh-keygen -f dotfiles_ssh -t rsa -b 4096 \
  && mv dotfiles_ssh.pub /home/$USER/.ssh/authorized_keys
# COPY .key/id_rsa.pub /root/.ssh/authorized_keys
# COPY --chown=$UID:$GID .key/id_rsa.pub /home/$USER/.ssh/authorized_keys

# repository
COPY --chown=$UID:$GID . /home/$USER/dotfiles
WORKDIR /home/$USER/dotfiles

RUN cd /home/$USER/dotfiles/ && zsh install.sh

ENV LANG=en_US.UTF-8
ENV USER=$USER

COPY entrypoint.sh /tmp/entrypoint.sh
USER root
CMD /tmp/entrypoint.sh


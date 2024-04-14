FROM --platform=amd64 ubuntu:22.04

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

RUN \
# Install Node 20 \
     curl -fsSL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh \
  && bash /tmp/nodesource_setup.sh \
  && apt-get install -y nodejs \
  && npm config set prefix '~/.local/' \
# Install Neovim \
#   && wget https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz \
#   && apt-get install ./nvim-linux64.deb \
#   && rm ./nvim-linux64.deb \
# Clean up \
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
  fi \
  && su $USER -c "mkdir /home/$USER/dotfiles"

# repository
COPY --chown=$UID:$GID install.sh /home/$USER/dotfiles/install.sh
COPY --chown=$UID:$GID nvim /home/$USER/dotfiles/nvim
COPY --chown=$UID:$GID shell /home/$USER/dotfiles/shell
COPY --chown=$UID:$GID tmux /home/$USER/dotfiles/tmux
COPY --chown=$UID:$GID tmux_scripts /home/$USER/dotfiles/tmux_scripts
WORKDIR /home/$USER/dotfiles

# Installation that requires sudo
RUN cd /home/$USER/dotfiles/ \
  && shell/setup_diff_highlight.sh $USER \
  && tar -C /tmp -xzf nvim/installer/nvim-linux64.tar.gz \
  && cp -r /tmp/nvim-linux64/bin /usr/local \
  && cp -r /tmp/nvim-linux64/lib /usr/local \
  && cp -r /tmp/nvim-linux64/share /usr/local \
  && cp -r /tmp/nvim-linux64/man/* /usr/local/man

USER $USER

# SSH key setting
# WORKDIR /home/$USER/.ssh
# RUN ssh-keygen -f dotfiles_ssh -t rsa -b 4096 \
#   && mv dotfiles_ssh.pub /home/$USER/.ssh/authorized_keys

RUN mkdir -p /home/$USER/host-disk \
  && mkdir -p /home/$USER/.config \
  && mkdir -p /home/$USER/.config/nvim \
  && mkdir -p /home/$USER/.config/nvim/colors \
  && git clone https://github.com/altercation/vim-colors-solarized.git /tmp/solarized \
  && cp /tmp/solarized/colors/solarized.vim /home/$USER/.config/nvim/colors/ \
  && cd /home/$USER/dotfiles/ \
  &&  ./install.sh --skip-sudo

ENV LANG=en_US.UTF-8
ENV USER=$USER

COPY docker/entrypoint.sh /tmp/entrypoint.sh
USER root

CMD /tmp/entrypoint.sh


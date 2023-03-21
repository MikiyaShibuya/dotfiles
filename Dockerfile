FROM ubuntu:20.04

ARG USER=docker

ENV DEBIAN_FRONTEND=noninteractive

# Install essential apt packages
RUN apt-get update \
  && apt-get install -y sudo git htop wget curl tmux zsh locales-all \
    software-properties-common python3-pip \
    libreadline-dev libffi-dev libncurses-dev \
    libssl-dev liblzma-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install neovim
RUN add-apt-repository ppa:neovim-ppa/unstable -y \
  && add-apt-repository ppa:deadsnakes/ppa -y \
  && apt-get update \
  && apt-get install -y neovim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install node \
RUN curl -fsSL https://deb.nodesource.com/setup_18.x -o /tmp/nodesource_setup.sh \
  && bash /tmp/nodesource_setup.sh \
  && apt-get install -y nodejs \
  && npm install -g neovim \
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
RUN useradd -s /bin/zsh -m $USER
RUN su $USER -c "mkdir /home/$USER/dotfiles"
RUN usermod -aG sudo shibuya

COPY .key/id_rsa.pub /root/.ssh/authorized_keys
COPY --chown=$UID:$GID .key/id_rsa.pub /home/$USER/.ssh/authorized_keys
COPY entrypoint.sh /tmp/entrypoint.sh
COPY install.sh shell/ nvim/ tmux/ tmux_scripts/ /home/$USER/dotfiles/

RUN su $USER -c "cd /home/$USER/dotfiles/ && zsh install.sh"

ENV LANG=en_US.UTF-8
ENV ENTRY_USER=$USER

CMD /tmp/entrypoint.sh


#!/bin/bash

#--- Setup ssh agen auth with one-liner ---
# curl -fsL https://raw.githubusercontent.com/MikiyaShibuya/dotfiles/refs/heads/master/shell/setup_ssh_agent_auth.sh  | sudo bash -s -- ~/.ssh/authorized_keys

if [[ `id -u` -ne 0 ]]; then
  echo Error: Run as ROOT
  exit 1
fi

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  echo Error: the OS is not Linux
  exit 1
fi

sudo apt-get install --no-install-recommends -y \
  libpam-ssh-agent-auth >> /dev/null

if grep -q "auth    sufficient  pam_ssh_agent_auth.so file=/etc/ssh/sudo_authorized_keys" /etc/pam.d/sudo; then
  echo "Skipped SSH agent auth setup (already in /etc/pam.d/sudo)"
else
  sed -i -n 'H;${x;s/^\n//;s/@include .*$/auth    sufficient  pam_ssh_agent_auth.so file=\/etc\/ssh\/sudo_authorized_keys\n\n&/;p;}' /etc/pam.d/sudo
fi

if grep -q "Defaults        env_keep += \"SSH_AUTH_SOCK\"" /etc/sudoers; then
  echo "Skipped SSH_AUTH_SOCK setup (already in /etc/sudoers)"
else
  echo 'Defaults        env_keep += "SSH_AUTH_SOCK"' >> /etc/sudoers
fi

if [ -z $1 ]; then
  echo No key path given, /etc/ssh/sudo_authorized_keys will be used
else
  cp $1 /etc/ssh/sudo_authorized_keys
fi

echo SSH agent auth setup done.

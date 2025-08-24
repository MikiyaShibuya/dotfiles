# Backlight control

In Ubuntu24.04, backlight brightness have bug which cause brightness to reset to 100% on resume from suspend.
This script will reset the brightness to the value before suspend.

## Install
```
sudo ln -s $PWD/monitor-unlock.sh /usr/local/bin/monitor-unlock.sh
sudo ln -s $PWD/monitor-unlock.service /etc/systemd/system/monitor-unlock.service
sudo systemctl enable --now monitor-unlock.service
```




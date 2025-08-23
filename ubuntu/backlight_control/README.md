# Backlight control

In Ubuntu24.04, backlight brightness have bug which cause brightness to reset to 100% on resume from suspend.
This script will reset the brightness to the value before suspend.

## Install
```
sudo cp reset-backlight-when-unlock /etc/systemd/system-sleep/reset-backlight-when-unlock
sudo chown root:root /etc/systemd/system-sleep/reset-backlight-when-unlock
```

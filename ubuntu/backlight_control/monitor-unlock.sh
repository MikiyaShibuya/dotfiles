#!/bin/bash


BRIGHTNESS_PATH="/sys/class/backlight/intel_backlight/brightness"
ACTUAL_BRIGHTNESS_PATH="/sys/class/backlight/intel_backlight/actual_brightness"
LOG_PATH="/var/log/reset_backlight_when_unlock.log"
N_MAX=10


gdbus monitor -y -d org.freedesktop.login1 |
while read -r line; do

  RESET_BRIGHTNESS=0

  # Example line when the PC back from idle:
  # /org/freedesktop/login1/session/_33: org.freedesktop.DBus.Properties.PropertiesChanged ('org.freedesktop.login1.Session', {'IdleHint': <false>, ...
  if echo "$line" | grep -q "PropertiesChanged" \
    && echo "$line" | grep -q "org.freedesktop.login1.Session"; then
    RESET_BRIGHTNESS=1
  fi

  # /org/freedesktop/login1: org.freedesktop.DBus.Properties.PropertiesChanged ('org.freedesktop.login1.Manager', {'BlockInhibited': <'handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch'>}, @as [])
  if echo "$line" | grep -q "PropertiesChanged" \
    && echo "$line" | grep -q "org.freedesktop.login1.Manager" \
    && echo "$line" | grep -q "'BlockInhibited': <'handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch'>"; then
    RESET_BRIGHTNESS=1
  fi

  if [ $RESET_BRIGHTNESS -eq 1 ]; then
    BRIGHTNESS=$(cat $BRIGHTNESS_PATH)

    for i in $(seq 1 $N_MAX); do
      ACTUAL_BRIGHTNESS=$(cat $ACTUAL_BRIGHTNESS_PATH)
      if [ "$BRIGHTNESS" = "$ACTUAL_BRIGHTNESS" ]; then
        echo "Brightness has set to $BRIGHTNESS ($i tries, $(date))" >> $LOG_PATH
        break
      else
        echo $BRIGHTNESS > $BRIGHTNESS_PATH
        sleep 0.05
      fi
    done

  fi
done

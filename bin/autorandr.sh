#!/bin/sh

PANEL_DEVICE=eDP-1
PANEL_DEVICE_MODE=1920x1080 # $(head -n 1 < /sys/class/drm/card0-${PANEL_DEVICE}/modes)

EXTERNAL_DEVICE=DP-1
EXTERNAL_DEVICE_STATUS=$(cat /sys/class/drm/card0-${EXTERNAL_DEVICE}/status)
EXTERNAL_DEVICE_MODE=$(head -n 1 < /sys/class/drm/card0-${EXTERNAL_DEVICE}/modes)

export DISPLAY=:0
export XAUTHORITY=/home/mholman/.Xauthority

if [ "${EXTERNAL_DEVICE_STATUS}" = disconnected ]; then
  xrandr --output "${PANEL_DEVICE}" --auto --primary --mode "${PANEL_DEVICE_MODE}"
  xrandr --output "${EXTERNAL_DEVICE}" --off
elif [ "${EXTERNAL_DEVICE_STATUS}" = connected ]; then
  # xrandr --output ${PANEL_DEVICE}    --auto --left-of  ${EXTERNAL_DEVICE} --mode $PANEL_DEVICE_MODE
  # xrandr --output ${EXTERNAL_DEVICE} --auto --right-of ${PANEL_DEVICE}     --primary --mode ${EXTERNAL_DEVICE_MODE}
  xrandr --output "${PANEL_DEVICE}"    --off
  xrandr --output "${EXTERNAL_DEVICE}" --auto --primary --mode "${EXTERNAL_DEVICE_MODE}"
else
  xrandr --auto
fi

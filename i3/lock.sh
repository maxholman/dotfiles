#!/usr/bin/env bash

revert() {
  xset dpms 0 0 0
}
trap revert SIGHUP SIGINT SIGTERM

gnome-screenshot -f ~/Pictures/lockscreen.png
convert ~/Pictures/lockscreen.png -colorspace gray -scale 12.5% -scale 800% ~/Pictures/lockscreen.png

i3lock --inactivity-timeout=10 --image ~/Pictures/lockscreen.png --nofork --ignore-empty-password --show-failed-attempts &
echo $!

xset +dpms dpms 5 5 5
xset dpms force off

revert

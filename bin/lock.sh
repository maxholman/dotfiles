#!/usr/bin/env bash

revert() {
  xset dpms 0 0 0
}
trap revert SIGHUP SIGINT SIGTERM

lockscrimage=~/Pictures/lockscreen.png

maim -m 1 | magick png:- -scale 12.5% -scale 800% -fill black -colorize 50% ${lockscrimage}

i3lock --image ${lockscrimage} --nofork --ignore-empty-password --show-failed-attempts &

echo $!

#xset +dpms dpms 5 5 5
#xset dpms force off

revert

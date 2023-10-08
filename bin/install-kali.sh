#!/usr/bin/env bash

set -e

INSTALL_DIR=~/.dotfiles
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .dotfiles main
if [ "$DIR" != "$INSTALL_DIR" ]; then
  ln -Tsf ${DIR} ${INSTALL_DIR}
fi

# X
ln -sf ${INSTALL_DIR}/.xinitrc ~
ln -sf ${INSTALL_DIR}/.Xresources ~

# i3 and wm stuff
ln -sf ${INSTALL_DIR}/.config/i3-kali ~/.config/i3
ln -sf ${INSTALL_DIR}/.config/i3blocks ~/.config/i3blocks
ln -sf ${INSTALL_DIR}/.config/rofi ~/.config/rofi

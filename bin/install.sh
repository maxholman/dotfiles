#!/usr/bin/env bash

set -e

INSTALL_DIR=~/.dotfiles
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# .dotfiles main
if [ "$DIR" != "$INSTALL_DIR" ]; then
    ln -Tsf ${DIR} ${INSTALL_DIR}
fi

# bash
ln -sf ${INSTALL_DIR}/.bashrc ~

# various
ln -sf ${INSTALL_DIR}/.gitconfig ~
ln -sf ${INSTALL_DIR}/.gitignore_global ~
ln -sf ${INSTALL_DIR}/.gtkrc-2.0 ~
ln -sf ${INSTALL_DIR}/.vim ~
ln -sf ${INSTALL_DIR}/.vimrc ~

# i3 and friends
ln -sf ${INSTALL_DIR}/.config/dunst ~/.config/dunst
ln -sf ${INSTALL_DIR}/.config/git ~/.config/git
ln -sf ${INSTALL_DIR}/.config/gtk-3.0 ~/.config/gtk-3.0
ln -sf ${INSTALL_DIR}/.config/i3 ~/.config/i3
ln -sf ${INSTALL_DIR}/.config/i3status ~/.config/i3status
ln -sf ${INSTALL_DIR}/.config/picom ~/.config/picom
ln -sf ${INSTALL_DIR}/.config/rofi ~/.config/rofi
ln -sf ${INSTALL_DIR}/.config/redshift ~/.config/redshift

# X
ln -sf ${INSTALL_DIR}/.xinitrc ~
ln -sf ${INSTALL_DIR}/.Xresources ~

# ssh
mkdir -p ~/.ssh/control
ln -sf ${INSTALL_DIR}/.ssh/config ~/.ssh/config

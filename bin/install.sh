#!/usr/bin/env bash

set -e
#set -x

INSTALL_DIR=~/.dotfiles
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# .dotfiles main
if [ "$DIR" != "$INSTALL_DIR" ]; then
    ln -Tsf ${DIR} ${INSTALL_DIR}
fi

# bash
ln -sf ${INSTALL_DIR}/.profile ~
ln -sf ${INSTALL_DIR}/bash/.rc ~/.bashrc

# git
ln -sf ${INSTALL_DIR}/git/.gitconfig ~

# i3 and friends
ln -sf ${INSTALL_DIR}/i3/config ~/.config/i3
ln -sf ${INSTALL_DIR}/picom/config ~/.config/picom
ln -sf ${INSTALL_DIR}/rofi/config.rasi ~/.config/rofi

# X
ln -sf ${INSTALL_DIR}/x/.xsessionrc ~
ln -sf ${INSTALL_DIR}/x/.Xresources ~

# vim
ln -sf ${INSTALL_DIR}/.vimrc ~

# dunst
mkdir -p ~/.config/dunst/
ln  -sf ${INSTALL_DIR}/x/dunstrc ~/.config/dunst/dunstrc

# ssh
mkdir -p ~/.ssh/control
ln -sf ${INSTALL_DIR}/ssh/config ~/.ssh/config

# sudoers
sudo cp ${INSTALL_DIR}/sudoers.d/* /etc/sudoers.d
sudo chmod 0400 /etc/sudoers.d/*

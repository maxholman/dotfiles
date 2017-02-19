#!/usr/bin/env bash

sudo apt install nvm

nvm install 7
nvm use 7
nvm alias default 7

# Globally install with npm

packages=(
  gulp
  nodemon
  npm-check
  npm-check-updates,
  dynamodump
)

npm install -g "${packages[@]}"
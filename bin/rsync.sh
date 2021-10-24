#!/usr/bin/env bash

trap popd EXIT
pushd "$PWD" || exit
cd "$(dirname "$0")" || exit

rsync -av \
      -e ssh \
      --partial \
      --delete \
      --delete-excluded \
      --inplace \
      --progress \
      --prune-empty-dirs \
      \
      -F \
      --files-from .rsync-files \
      --recursive \
      "$@" \
      \
      "$HOME/" \
      \
      ws1:/media/storage/mholman/ws6"$HOME"


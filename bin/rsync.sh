#!/usr/bin/env bash

trap popd EXIT
pushd "$PWD" || exit
cd "$(dirname "$0")" || exit

SRC=${HOME}/

DEST_HOST=
DEST_PATH=

rsync -av \
      -e ssh \
      --partial \
      --delete \
      --delete-excluded \
      --progress \
      --prune-empty-dirs \
      \
      -F \
      --files-from .rsync-files \
      -f 'merge .rsync-filter' \
      --recursive \
      "${SRC}" \
      \
      "${DEST_HOST}:${DEST_PATH}"

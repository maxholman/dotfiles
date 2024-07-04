#!/usr/bin/env bash

trap popd EXIT
pushd "$PWD" || exit
cd "$(dirname "$0")" || exit

SRC=${HOME}/

DEST_USER=max
DEST_HOST=nas1.svc.dc1.holmn.net
DEST_PATH=/mnt/primary/enc/homes/max

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
  -f 'merge backups-filter' \
  --recursive \
  "${SRC}" \
  \
  "${DEST_USER}@${DEST_HOST}:${DEST_PATH}"

# \
#   --dry-run \
#   --itemize-changes \
#   \

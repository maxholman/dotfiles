#!/usr/bin/env bash

set -oex

trap popd EXIT
pushd "$PWD" || exit
cd "$(dirname "$0")" || exit

SRC=${SRC:-/media/storage/backups}
DEST=${DEST:-/dev/null}

rclone \
	--config ~/.config/rclone/rclone.conf \
	--transfers 32 \
	--filter-from backups-filter \
	--verbose \
	--progress \
	--skip-links \
	sync \
	${SRC} \
	${DEST}

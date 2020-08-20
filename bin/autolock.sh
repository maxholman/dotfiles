#!/usr/bin/env bash

set -eu

logfile=~/.autolock.log

pushd `dirname $0` > /dev/null

cmd=${1:-lock}

# Is the screen already locked?
locked() { pkill -0 --euid "$(id -u)" --exact i3lock; }

# Return 0 if suspend is acceptable.
suspend_ok() {
  #[ -n "$(2>/dev/null mpc current)" ] && return 1
  return 0
}

# Print the given message with a timestamp.
info() { printf '%s\t%s\n' "$(date)" "$*"; }

log() {
  if [ -n "${logfile:-}" ]; then
    info >>"$logfile" "$@"
  else
    info "$@"
  fi
}

# Control the dunst daemon, if it is running.
dunst() {
  pkill -0 --exact dunst || return 0

  case ${1:-} in
    stop)
      log "Stopping notifications and locking screen."
      pkill -USR1 --euid "$(id -u)" --exact dunst
      ;;
    resume)
      log "...Resuming notifications."
      pkill -USR2 --euid "$(id -u)" --exact dunst
      ;;
    *)
      echo "dunst argument required: stop or resume"
      return 1
      ;;
  esac
}

case "$cmd" in
  lock)
    dunst stop

    # Fork both i3lock and its monitor to avoid blocking xautolock.
    #i3lock --ignore-empty-password --beep --inactivity-timeout=10 --image="$XDG_CONFIG_HOME/i3/i3lock-img" --nofork &
    ./lock.sh

    pid=$(pidof i3lock)
    log "Waiting for PID(s) $pid to end..."
    while 2>/dev/null kill -0 "$pid"; do
      sleep 1
    done

    dunst resume
    ;;

  notify)
    # Notification should not be issued while locked even if dunst is paused.
    locked && exit

    log "Sending notification."
    notify-send --urgency="normal" --app-name="xautolock" -- "Screen will lock shortly..."
    ;;

  suspend)
    if suspend_ok; then
      log "Suspending system."
      systemctl suspend
    else
      log "Deferring suspend."
    fi
    ;;

  debug)
    log "$@"
    ;;

  *)
    log "Unrecognized option: $1"
esac

popd > /dev/null

#!/usr/bin/env bash
set -euo pipefail

OUTDIR="${HOME}/Videos/recordings"
mkdir -p "$OUTDIR"
PIDFILE="/tmp/sway-record.pid"

notify() { command -v notify-send >/dev/null && notify-send "record.sh" "$1"; }

is_recording() {
  [ -f "$PIDFILE" ] || return 1
  PID=$(cut -d: -f1 < "$PIDFILE" 2>/dev/null || true)
  [ -n "$PID" ] && kill -0 "$PID" >/dev/null 2>&1
}

start_recording() {
  if ! command -v wf-recorder >/dev/null 2>&1; then
    notify "wf-recorder not found; please install it."
    exit 1
  fi

  TS=$(date +%Y%m%d-%H%M%S)
  OUTFILE="$OUTDIR/screen-$TS.mp4"

  # select output (requires slurp)
  # If you want full screen of focused output, you can use:
  # OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
  # wf-recorder -o "$OUTPUT" -f "$OUTFILE" ...
  
  # Check if we want audio
  # This simple version records video only by default to keep it robust.
  # To add audio: -a
  
  # Start wf-recorder in background
  # Uses default codec (usually h264/libx264 or vaapi if configured)
  nohup wf-recorder -f "$OUTFILE" >/dev/null 2>&1 &
  PID=$!
  
  printf "%d:%s" "$PID" "$OUTFILE" > "$PIDFILE"
  notify "Recording started: $OUTFILE"
}

stop_recording() {
  if [ -f "$PIDFILE" ]; then
    PID=$(cut -d: -f1 < "$PIDFILE" 2>/dev/null || true)
    OUTPATH=$(cut -d: -f2- < "$PIDFILE" 2>/dev/null || true)
    if [ -n "$PID" ]; then
      kill -INT "$PID" >/dev/null 2>&1 || true
      # wait for graceful exit
      sleep 1
    fi
    rm -f "$PIDFILE"
    notify "Recording stopped: $OUTPATH"
  else
    notify "No recording in progress"
  fi
}

case "${1:-toggle}" in
  start)
    if is_recording; then notify "Already recording"; exit 0; fi
    start_recording
    ;;
  stop)
    stop_recording
    ;;
  toggle)
    if is_recording; then stop_recording; else start_recording; fi
    ;;
  *)
    echo "Usage: $0 {start|stop|toggle}"
    exit 2
    ;;
esac

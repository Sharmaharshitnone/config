#!/usr/bin/env bash
set -euo pipefail

OUTDIR="${HOME}/Videos/recordings"
mkdir -p "$OUTDIR"
PIDFILE="/tmp/screen-record.pid"

notify() { command -v notify-send >/dev/null && notify-send "record.sh" "$1"; }

get_resolution() {
  # Prefer xdpyinfo, fallback to xrandr, else default
  # Note: using 'head -1' instead of 'awk exit' to avoid SIGPIPE issues with pipefail
  if command -v xdpyinfo >/dev/null 2>&1; then
    xdpyinfo | awk '/dimensions:/ {print $2}' | head -1
  elif command -v xrandr >/dev/null 2>&1; then
    xrandr | awk '/\*/{print $1}' | head -1
  else
    # last-resort default
    printf "1280x720"
  fi
}

is_recording() {
  [ -f "$PIDFILE" ] || return 1
  PID=$(cut -d: -f1 < "$PIDFILE" 2>/dev/null || true)
  [ -n "$PID" ] && kill -0 "$PID" >/dev/null 2>&1
}

start_x11() {
  if ! type ffmpeg >/dev/null 2>&1; then
    notify "ffmpeg not found; please install ffmpeg"
    echo "ffmpeg not found" >&2
    return 127
  fi

  # Check for pactl (needed to get default sink monitor for system audio)
  if ! type pactl >/dev/null 2>&1; then
    notify "pactl not found; please install pulseaudio-utils"
    echo "pactl not found" >&2
    return 127
  fi

  TS=$(date +%Y%m%d-%H%M%S)
  OUTFILE="$OUTDIR/screen-$TS.mkv"

  RES=$(get_resolution)
  if [ -z "$RES" ]; then
    notify "Unable to determine display resolution"
    echo "Unable to determine display resolution" >&2
    return 1
  fi

  # Get the default sink's monitor for system audio capture
  DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null || echo "")
  if [ -z "$DEFAULT_SINK" ]; then
    notify "Unable to detect default audio sink"
    echo "Unable to detect default audio sink" >&2
    return 1
  fi
  AUDIO_INPUT="${DEFAULT_SINK}.monitor"

  # Start ffmpeg in background (capture system audio via monitor)
  ffmpeg -video_size "$RES" -framerate 30 -f x11grab -i "${DISPLAY:-:0.0}" \
    -f pulse -i "$AUDIO_INPUT" \
    -c:v libx264 -preset veryfast -crf 18 -c:a aac -b:a 128k "$OUTFILE" >/dev/null 2>&1 &
  PID=$!
  # store PID and outfile so stop can read the real output path
  printf "%d:%s" "$PID" "$OUTFILE" > "$PIDFILE"
  notify "Recording started: $OUTFILE"
}

stop_record() {
  if [ -f "$PIDFILE" ]; then
    PID=$(cut -d: -f1 < "$PIDFILE" 2>/dev/null || true)
    OUTPATH=$(cut -d: -f2- < "$PIDFILE" 2>/dev/null || true)
    if [ -n "$PID" ]; then
      kill -INT "$PID" >/dev/null 2>&1 || kill -TERM "$PID" >/dev/null 2>&1 || true
      # wait a moment for ffmpeg to flush file
      sleep 1
    fi
    rm -f "$PIDFILE"
    if [ -n "$OUTPATH" ]; then
      notify "Recording stopped: $OUTPATH"
    else
      notify "Recording stopped"
    fi
  else
    notify "No recording in progress"
  fi
}

case "${1:-toggle}" in
  start)
    if is_recording; then notify "Already recording"; exit 0; fi
    start_x11
    ;;
  stop)
    stop_record
    ;;
  toggle)
    if is_recording; then stop_record; else start_x11; fi
    ;;
  *)
    echo "Usage: $0 {start|stop|toggle}"
    exit 2
    ;;
esac

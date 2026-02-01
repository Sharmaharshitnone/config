#!/usr/bin/env bash
set -euo pipefail

# Window-selection screen recorder with microphone input
# Dependencies: slop, ffmpeg, pactl

OUTDIR="${HOME}/Videos/recordings"
mkdir -p "$OUTDIR"
PIDFILE="/tmp/screen-record-window-mic.pid"

notify() { command -v notify-send >/dev/null && notify-send "record-window-mic.sh" "$1"; }

check_deps() {
  local missing=()
  for dep in slop ffmpeg pactl; do
    command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
  done
  
  if [ ${#missing[@]} -gt 0 ]; then
    notify "Missing dependencies: ${missing[*]}"
    echo "Missing dependencies: ${missing[*]}" >&2
    echo "Install with: sudo pacman -S slop ffmpeg libpulse" >&2
    return 127
  fi
  return 0
}

is_recording() {
  [ -f "$PIDFILE" ] || return 1
  PID=$(cut -d: -f1 < "$PIDFILE" 2>/dev/null || true)
  [ -n "$PID" ] && kill -0 "$PID" >/dev/null 2>&1
}

get_window_geometry() {
  # Use slop to select window/region
  # Returns: WIDTHxHEIGHT+X+Y format
  # -f: format output, -q: quiet mode
  slop -f "%wx%h+%x+%y" 2>/dev/null || {
    notify "Window selection cancelled"
    return 1
  }
}

start_recording() {
  check_deps || return $?

  if is_recording; then
    notify "Already recording a window"
    return 1
  fi

  TS=$(date +%Y%m%d-%H%M%S)
  OUTFILE="$OUTDIR/window-mic-$TS.mkv"

  # Prompt user to select window
  notify "Select window/region to record..."
  GEOMETRY=$(get_window_geometry) || return 1

  # Parse geometry: WIDTHxHEIGHT+X+Y
  if [ -z "$GEOMETRY" ]; then
    notify "Invalid geometry from slop"
    return 1
  fi

  # Get system audio (desktop audio)
  DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null || echo "")
  if [ -z "$DEFAULT_SINK" ]; then
    notify "Unable to detect default audio sink"
    echo "Unable to detect default audio sink" >&2
    return 1
  fi
  SYSTEM_AUDIO="${DEFAULT_SINK}.monitor"

  # Get microphone input
  MIC_INPUT=$(pactl get-default-source 2>/dev/null || echo "default")

  # Extract WIDTH and HEIGHT for even values (x264 requirement)
  WIDTH=$(echo "$GEOMETRY" | awk -F'[x+]' '{print $1}')
  HEIGHT=$(echo "$GEOMETRY" | awk -F'[x+]' '{print $2}')
  X_OFFSET=$(echo "$GEOMETRY" | awk -F'[x+]' '{print $3}')
  Y_OFFSET=$(echo "$GEOMETRY" | awk -F'[x+]' '{print $4}')
  
  # Make dimensions even (required for x264)
  WIDTH=$((WIDTH - WIDTH % 2))
  HEIGHT=$((HEIGHT - HEIGHT % 2))

  # Start ffmpeg with hardware-accelerated capture
  # VAAPI: Uses Intel QuickSync (i7-13620H iGPU) for zero-CPU encoding
  # -vaapi_device: Hardware encoder device (Intel/AMD on Arch)
  # -vf format=nv12,hwupload: Convert to GPU-compatible format and upload to VRAM
  # -c:v h264_vaapi: Hardware H.264 encoder (replaces CPU-bound libx264)
  # -qp 24: Constant quality mode for VAAPI (18-28 range, lower=better)
  # -framerate 60: Hardware can handle 60fps without CPU penalty
  LOGFILE="/tmp/ffmpeg-window-mic-${TS}.log"
  ffmpeg \
    -f x11grab \
    -video_size "${WIDTH}x${HEIGHT}" \
    -framerate 60 \
    -i "${DISPLAY:-:0.0}+${X_OFFSET},${Y_OFFSET}" \
    -f pulse -i "$SYSTEM_AUDIO" \
    -f pulse -i "$MIC_INPUT" \
    -filter_complex "[1:a][2:a]amix=inputs=2:duration=longest[aout]" \
    -map 0:v -map "[aout]" \
    -vaapi_device /dev/dri/renderD128 \
    -vf "format=nv12,hwupload" \
    -c:v h264_vaapi -qp 20 \
    -c:a aac -b:a 192k \
    "$OUTFILE" >"$LOGFILE" 2>&1 &
  
  PID=$!
  
  # Validate ffmpeg actually started
  sleep 0.5
  if ! kill -0 "$PID" 2>/dev/null; then
    notify "Failed to start recording. Check $LOGFILE"
    cat "$LOGFILE" >&2
    return 1
  fi
  
  printf "%d:%s" "$PID" "$OUTFILE" > "$PIDFILE"
  notify "Recording window (system + mic): ${WIDTH}x${HEIGHT}"
}

stop_recording() {
  if [ -f "$PIDFILE" ]; then
    PID=$(cut -d: -f1 < "$PIDFILE" 2>/dev/null || true)
    OUTPATH=$(cut -d: -f2- < "$PIDFILE" 2>/dev/null || true)
    
    if [ -n "$PID" ]; then
      # Send INT signal to ffmpeg for clean shutdown
      kill -INT "$PID" >/dev/null 2>&1 || kill -TERM "$PID" >/dev/null 2>&1 || true
      sleep 1
    fi
    
    rm -f "$PIDFILE"
    
    if [ -n "$OUTPATH" ] && [ -f "$OUTPATH" ]; then
      SIZE=$(du -h "$OUTPATH" | cut -f1)
      notify "Recording stopped: $OUTPATH ($SIZE)"
    else
      notify "Recording stopped"
    fi
  else
    notify "No recording in progress"
  fi
}

case "${1:-toggle}" in
  start)
    start_recording
    ;;
  stop)
    stop_recording
    ;;
  toggle)
    if is_recording; then
      stop_recording
    else
      start_recording
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|toggle}" >&2
    exit 1
    ;;
esac

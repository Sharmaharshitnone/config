#!/usr/bin/env bash
set -euo pipefail

# Window-selection screen recorder with microphone input
# Dependencies: slop, ffmpeg, pactl
# Supports: Intel iGPU (VAAPI), Nvidia dGPU (NVENC), Software fallback (libx264)

OUTDIR="${HOME}/Videos/recordings"
mkdir -p "$OUTDIR"
PIDFILE="/tmp/screen-record-window-mic.pid"

notify() { command -v notify-send >/dev/null && notify-send "record-window-mic.sh" "$1"; }
log()    { echo "[record-window-mic] $*" >&2; }

# ─── Dependency check ──────────────────────────────────────────────────────────
check_deps() {
  local missing=()
  for dep in slop ffmpeg pactl; do
    command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
  done
  if (( ${#missing[@]} > 0 )); then
    notify "Missing dependencies: ${missing[*]}"
    log "Missing: ${missing[*]} — Install with: sudo pacman -S slop ffmpeg libpulse"
    return 127
  fi
}

# ─── GPU / encoder detection ──────────────────────────────────────────────────
# Priority: NVENC (Nvidia) → VAAPI (Intel/AMD) → libx264 (CPU)
# Returns: "nvenc" | "vaapi" | "software"
detect_encoder() {
  # Capture encoder list once. We use process substitution into a variable rather than
  # piping directly into grep, because `set -o pipefail` causes any broken pipe (SIGPIPE)
  # from ffmpeg when grep exits early after a match to propagate as a pipeline failure,
  # making the `if pipeline` condition evaluate false even on a successful match.
  local encoders
  encoders=$(ffmpeg -hide_banner -encoders 2>/dev/null) || true

  # NVENC: Nvidia hardware H.264 encoder.
  # Two conditions must both be true:
  #   1. ffmpeg was compiled with NVENC support (h264_nvenc appears in encoder list)
  #   2. Nvidia kernel driver is running — /dev/nvidiactl is the canonical probe;
  #      created by nvidia.ko, present whenever the driver is loaded, even without
  #      nvidia-utils or nvidia-smi installed.
  if grep -q 'h264_nvenc' <<< "$encoders" && [[ -c /dev/nvidiactl ]]; then
    echo "nvenc"; return 0
  fi

  # VAAPI: Intel QuickSync / AMD VCE via DRI render node.
  # Requires: intel-media-driver (Intel) or libva-mesa-driver (AMD) + libva runtime.
  # Only use VAAPI against non-Nvidia renderD nodes (Nvidia does not support VAAPI).
  if grep -q 'h264_vaapi' <<< "$encoders"; then
    local dev
    dev=$(find_vaapi_device)
    if [[ -n "$dev" ]]; then
      if command -v vainfo &>/dev/null; then
        vainfo --display drm --device "$dev" &>/dev/null && { echo "vaapi"; return 0; }
      else
        # vainfo not installed — trust the vendor ID check from find_vaapi_device
        echo "vaapi"; return 0
      fi
    fi
  fi

  # Software fallback: CPU libx264 — always available in standard ffmpeg builds
  echo "software"
}

# Find the Intel/AMD renderD device (vendor 0x8086 = Intel, 0x1002 = AMD)
# Skips Nvidia renderD nodes (0x10de) so VAAPI doesn't accidentally try them.
find_vaapi_device() {
  # The sysfs path for renderD128 is:
  #   /sys/class/drm/renderD128/device/vendor   (Linux 5.x+, direct symlink exists)
  # Vendor IDs: 0x8086 = Intel, 0x1002 = AMD, 0x10de = Nvidia (skip)
  local renderD vendor sysfs_vendor
  for renderD in /dev/dri/renderD[0-9]*; do
    [[ -c "$renderD" ]] || continue
    local node
    node=$(basename "$renderD")   # e.g. renderD128
    # Primary probe: direct sysfs path (works on most kernels)
    sysfs_vendor="/sys/class/drm/${node}/device/vendor"
    vendor=$(cat "$sysfs_vendor" 2>/dev/null || echo "")
    # Secondary probe: via card symlink if direct path absent
    if [[ -z "$vendor" ]]; then
      local card_path
      card_path=$(readlink -f "/sys/class/drm/${node}" 2>/dev/null || true)
      [[ -n "$card_path" ]] && vendor=$(cat "${card_path}/device/vendor" 2>/dev/null || echo "")
    fi
    case "$vendor" in
      0x8086|0x1002) echo "$renderD"; return 0 ;;  # Intel / AMD — VAAPI capable
      0x10de)        continue ;;                    # Nvidia — no VAAPI, skip
      *)
        # Unknown or unreadable vendor: skip to be safe
        log "renderD $renderD vendor='$vendor' — skipping (unrecognised)"
        continue ;;
    esac
  done
  echo ""  # no suitable device found
}

# ─── State / PID helpers ──────────────────────────────────────────────────────
# Returns 0 if ffmpeg process is genuinely alive, 1 otherwise.
# Also cleans up a stale PIDFILE (process died unexpectedly — e.g., encoder crash).
is_recording() {
  [[ -f "$PIDFILE" ]] || return 1
  local pid
  pid=$(cut -d: -f1 < "$PIDFILE" 2>/dev/null || true)
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    return 0  # alive
  fi
  # Process is gone but PIDFILE is still here → stale lock, clean it up
  log "Stale PIDFILE detected (PID $pid exited). Cleaning up."
  rm -f "$PIDFILE"
  return 1
}

# ─── Geometry selector ────────────────────────────────────────────────────────
get_window_geometry() {
  slop -f "%wx%h+%x+%y" 2>/dev/null || {
    notify "Window selection cancelled"
    return 1
  }
}

# ─── Core recorder ────────────────────────────────────────────────────────────
start_recording() {
  check_deps || return $?

  if is_recording; then
    notify "Already recording a window"
    return 1
  fi

  # Detect encoder BEFORE user selection so we warn early
  local encoder
  encoder=$(detect_encoder)
  log "GPU encoder selected: $encoder"

  TS=$(date +%Y%m%d-%H%M%S)
  OUTFILE="$OUTDIR/window-mic-$TS.mkv"
  LOGFILE="/tmp/ffmpeg-window-mic-${TS}.log"

  notify "Select window/region to record... [encoder: $encoder]"
  local GEOMETRY
  GEOMETRY=$(get_window_geometry) || return 1

  [[ -n "$GEOMETRY" ]] || { notify "Invalid geometry from slop"; return 1; }

  # Audio sources
  local DEFAULT_SINK
  DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null || true)
  if [[ -z "$DEFAULT_SINK" ]]; then
    notify "Unable to detect default audio sink"; log "pactl get-default-sink failed"; return 1
  fi
  local SYSTEM_AUDIO="${DEFAULT_SINK}.monitor"
  local MIC_INPUT
  MIC_INPUT=$(pactl get-default-source 2>/dev/null || echo "default")

  # Parse geometry: WIDTHxHEIGHT+X+Y
  local WIDTH HEIGHT X_OFFSET Y_OFFSET
  WIDTH=$(echo "$GEOMETRY"   | awk -F'[x+]' '{print $1}')
  HEIGHT=$(echo "$GEOMETRY"  | awk -F'[x+]' '{print $2}')
  X_OFFSET=$(echo "$GEOMETRY"| awk -F'[x+]' '{print $3}')
  Y_OFFSET=$(echo "$GEOMETRY"| awk -F'[x+]' '{print $4}')

  # x264/NVENC/VAAPI all require even dimensions
  WIDTH=$(( WIDTH  - WIDTH  % 2 ))
  HEIGHT=$(( HEIGHT - HEIGHT % 2 ))

  # ── Build ffmpeg command array (avoids quoting hell) ──────────────────────
  local -a ffmpeg_cmd=(
    ffmpeg
    -f x11grab
    -video_size "${WIDTH}x${HEIGHT}"
    -framerate 60
    -i "${DISPLAY:-:0}+${X_OFFSET},${Y_OFFSET}"
    -f pulse -i "$SYSTEM_AUDIO"
    -f pulse -i "$MIC_INPUT"
    -filter_complex "[1:a][2:a]amix=inputs=2:duration=longest[aout]"
    -map 0:v -map "[aout]"
    -c:a aac -b:a 192k
  )

  case "$encoder" in
    nvenc)
      # NVENC: Nvidia hardware H.264 encoder
      # -preset p4: balanced quality/speed (p1=fastest … p7=best quality)
      # -rc vbr: variable bitrate (better quality than cbr for screen content)
      # -cq 20: constant quality target (0-51, lower=better; ~20 is visually lossless)
      # -b:v 0: let CQ control bitrate rather than a hard cap
      ffmpeg_cmd+=(
        -c:v h264_nvenc
        -preset p4
        -rc vbr -cq 20 -b:v 0
      )
      log "Using Nvidia NVENC (h264_nvenc, CQ=20)"
      ;;
    vaapi)
      # VAAPI: Intel QuickSync / AMD VCE via DRI
      # hwupload uploads YUV frames from CPU to GPU memory
      # -qp 20: constant quality (18-28 range; lower=better)
      local vaapi_dev
      vaapi_dev=$(find_vaapi_device)
      if [[ -n "$vaapi_dev" ]]; then
        ffmpeg_cmd+=(
          -vaapi_device "$vaapi_dev"
          -vf "format=nv12,hwupload"
          -c:v h264_vaapi -qp 20
        )
        log "Using Intel/AMD VAAPI (h264_vaapi, QP=20, device=$vaapi_dev)"
      else
        # No VAAPI device found: degrade to libx264
        log "VAAPI device not found, degrading to software (libx264)"
        ffmpeg_cmd+=(-c:v libx264 -preset fast -crf 20)
      fi
      ;;
    *)
      # software / any unknown value → CPU libx264
      # -crf 20: constant rate factor (18-28 range; ~20 = visually lossless for screencaps)
      # -preset fast: good speed/quality trade-off for real-time encoding
      ffmpeg_cmd+=(
        -c:v libx264 -preset fast -crf 20
      )
      log "Using software encoding (libx264, CRF=20)"
      ;;
  esac

  ffmpeg_cmd+=("$OUTFILE")

  # Launch ffmpeg in background, redirect all output to logfile
  "${ffmpeg_cmd[@]}" >"$LOGFILE" 2>&1 &
  local PID=$!

  # Give ffmpeg time to initialize and fail fast if the encoder is broken
  # 1.5s catches VAAPI/NVENC init failures that the old 0.5s window missed
  if ! kill -0 "$PID" 2>/dev/null; then
    notify "Failed to start recording [encoder=$encoder]. See $LOGFILE"
    log "ffmpeg exited early. Last lines of log:"
    tail -20 "$LOGFILE" >&2
    return 1
  fi

  # Encode PID and output path into PIDFILE (: separator, path has no colons)
  printf '%d:%s\n' "$PID" "$OUTFILE" > "$PIDFILE"
  notify "Recording started [${encoder}] ${WIDTH}x${HEIGHT} → $(basename "$OUTFILE")"
  log "ffmpeg PID=$PID, output=$OUTFILE, log=$LOGFILE"
}

# ─── Stopper ──────────────────────────────────────────────────────────────────
stop_recording() {
  if [[ ! -f "$PIDFILE" ]]; then
    notify "No recording in progress"; return 0
  fi

  local PID OUTPATH
  PID=$(cut -d: -f1 < "$PIDFILE" 2>/dev/null || true)
  OUTPATH=$(cut -d: -f2- < "$PIDFILE" 2>/dev/null || true)

  if [[ -n "$PID" ]]; then
    if kill -0 "$PID" 2>/dev/null; then
      # SIGINT triggers ffmpeg's graceful shutdown (flushes buffers, writes moov atom)
      kill -INT "$PID" 2>/dev/null || true
      # Wait up to 5s for clean exit before forcing SIGTERM.
      # NOTE: (( waited++ )) post-increments: when waited=0 the expression evaluates
      # to 0, which bash sees as exit code 1 — that would trigger set -e and kill the
      # script before rm -f "$PIDFILE" runs, leaving a stale lock every single time.
      # (( ++waited )) pre-increments: always evaluates to >=1, exit code 0. Safe.
      local waited=0
      while kill -0 "$PID" 2>/dev/null && (( waited < 50 )); do
        sleep 0.1; (( ++waited ))
      done
      kill -0 "$PID" 2>/dev/null && kill -TERM "$PID" 2>/dev/null || true
    else
      log "ffmpeg (PID $PID) was no longer running at stop time"
    fi
  fi

  rm -f "$PIDFILE"

  if [[ -n "$OUTPATH" && -f "$OUTPATH" ]]; then
    local SIZE
    SIZE=$(du -h "$OUTPATH" | cut -f1)
    notify "Saved: $(basename "$OUTPATH") ($SIZE)"
    log "Output: $OUTPATH ($SIZE)"
  else
    notify "Recording stopped (output file missing — check /tmp/ffmpeg-window-mic-*.log)"
    log "Warning: output file '$OUTPATH' not found"
  fi
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────
case "${1:-toggle}" in
  start)  start_recording ;;
  stop)   stop_recording  ;;
  status)
    if is_recording; then
      PID=$(cut -d: -f1 < "$PIDFILE")
      OUTPATH=$(cut -d: -f2- < "$PIDFILE")
      echo "Recording active: PID=$PID, output=$(basename "$OUTPATH")"
    else
      echo "Not recording"
    fi
    ;;
  toggle)
    if is_recording; then stop_recording
    else start_recording
    fi
    ;;
  debug)
    log "=== GPU detection ==="
    enc=$(detect_encoder)
    log "Detected encoder: $enc"
    [[ "$enc" == "vaapi" ]] && log "VAAPI device: $(find_vaapi_device)"
    log "ffmpeg encoders (hw):"
    ffmpeg -hide_banner -encoders 2>/dev/null | grep -E 'nvenc|vaapi|qsv' || log "(none found)"
    log "DRI render nodes:"
    ls -la /dev/dri/render* 2>/dev/null || log "(none)"
    log "DISPLAY=$DISPLAY"
    ;;
  *)
    echo "Usage: $0 {start|stop|toggle|status|debug}" >&2
    exit 1
    ;;
esac

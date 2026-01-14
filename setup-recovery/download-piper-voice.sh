#!/usr/bin/env bash
# Download Piper TTS voice model: en_US-lessac-medium
# Simple script - downloads only the voice you're using

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

PIPER_VOICES_DIR="$HOME/.local/share/piper-voices"
VOICE="en_US-lessac-medium"
VOICE_URL="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium"

echo "========================================================"
echo "   Download Piper TTS Voice: $VOICE"
echo "========================================================"
echo ""

# Check wget
if ! command -v wget &>/dev/null; then
    log_error "wget not found. Install: sudo pacman -S wget"
fi

# Create directory
log_info "Creating voice directory: $PIPER_VOICES_DIR"
mkdir -p "$PIPER_VOICES_DIR"

# Download model file
MODEL_FILE="$PIPER_VOICES_DIR/$VOICE.onnx"
if [[ ! -f "$MODEL_FILE" ]]; then
    log_info "Downloading $VOICE.onnx..."
    if wget -O "$MODEL_FILE" "$VOICE_URL/$VOICE.onnx"; then
        log_info "✓ Downloaded: $VOICE.onnx"
    else
        log_error "Failed to download $VOICE.onnx"
    fi
else
    log_info "✓ Already exists: $VOICE.onnx"
fi

# Download config file
CONFIG_FILE="$PIPER_VOICES_DIR/$VOICE.onnx.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_info "Downloading $VOICE.onnx.json..."
    if wget -O "$CONFIG_FILE" "$VOICE_URL/$VOICE.onnx.json"; then
        log_info "✓ Downloaded: $VOICE.onnx.json"
    else
        log_error "Failed to download $VOICE.onnx.json"
    fi
else
    log_info "✓ Already exists: $VOICE.onnx.json"
fi

echo ""
echo "========================================================"
log_info "✓ Voice download complete!"
echo "========================================================"
echo ""
log_info "Test with: spd-say 'Hello world'"
echo ""

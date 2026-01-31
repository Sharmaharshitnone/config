#!/bin/bash
# fontconfig/test-config.sh
# Validates fontconfig configuration and font availability
# Usage: ./test-config.sh [path-to-fonts.conf]

set -euo pipefail

# Allow custom config path, default to current directory
CONFIG="${1:-./fonts.conf}"

# ANSI colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Fontconfig Validation Suite ==="
echo "Testing: $CONFIG"
echo ""

# Track failures
FAILURES=0

# Function to print test results
pass() { echo -e "${GREEN}PASS${NC}: $1"; }
fail() { echo -e "${RED}FAIL${NC}: $1"; ((FAILURES++)); }
warn() { echo -e "${YELLOW}WARN${NC}: $1"; }

# Test 1: XML Syntax Validation
echo "--- XML Syntax Check ---"
if command -v xmllint &> /dev/null; then
    if xmllint --noout "$CONFIG" 2>/dev/null; then
        pass "XML is well-formed"
    else
        fail "XML syntax errors found"
    fi
else
    warn "xmllint not installed, skipping XML validation"
fi
echo ""

# Test 2: Alias Resolution
echo "--- Alias Resolution ---"
for family in serif sans-serif monospace; do
    if command -v fc-match &> /dev/null; then
        result=$(fc-match -f '%{family}\n' "$family" 2>/dev/null || echo "ERROR")
        echo "  $family → $result"
    else
        warn "fc-match not installed, skipping"
        break
    fi
done
echo ""

# Test 3: Proprietary Font Substitutions
echo "--- Font Substitutions ---"
declare -A SUBS=(
    ["Arial"]="Noto Sans"
    ["Helvetica"]="Noto Sans"
    ["Times New Roman"]="Noto Serif"
    ["Courier New"]="JetBrainsMono Nerd Font"
)

if command -v fc-match &> /dev/null; then
    for font in "${!SUBS[@]}"; do
        expected="${SUBS[$font]}"
        result=$(fc-match -f '%{family}\n' "$font" 2>/dev/null || echo "ERROR")
        if [[ "$result" == *"$expected"* ]]; then
            pass "$font → $result"
        else
            warn "$font → $result (expected $expected)"
        fi
    done
else
    warn "fc-match not installed, skipping substitution tests"
fi
echo ""

# Test 4: Emoji Resolution
echo "--- Emoji Resolution ---"
if command -v fc-match &> /dev/null; then
    for family in emoji "Apple Color Emoji" "Segoe UI Emoji"; do
        result=$(fc-match -f '%{family}\n' "$family" 2>/dev/null || echo "ERROR")
        echo "  $family → $result"
    done
else
    warn "fc-match not installed, skipping emoji tests"
fi
echo ""

# Test 5: Required Font Availability
echo "--- Required Fonts Check ---"
REQUIRED_FONTS=(
    "Noto Serif"
    "Noto Sans"
    "JetBrainsMono Nerd Font"
    "Noto Color Emoji"
)

if command -v fc-list &> /dev/null; then
    for font in "${REQUIRED_FONTS[@]}"; do
        if fc-list | grep -qi "$font"; then
            pass "$font installed"
        else
            warn "$font not found (fallback fonts will be used)"
        fi
    done
else
    warn "fc-list not installed, skipping font availability check"
fi
echo ""

# Summary
echo "=== Summary ==="
if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}All critical tests passed${NC}"
    exit 0
else
    echo -e "${RED}$FAILURES critical test(s) failed${NC}"
    exit 1
fi

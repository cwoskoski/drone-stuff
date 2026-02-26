#!/usr/bin/env bash
# Extract DJI Fly APK from device and decompile with jadx
# Usage: bash extract_and_decompile.sh [device_serial]
set -euo pipefail

JADX="$HOME/tools/jadx/bin/jadx"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/decompiled"
APK_DIR="$SCRIPT_DIR/apks"
ADB="${ANDROID_HOME:-$HOME/Android}/platform-tools/adb"

DEVICE_FLAG=""
if [ "${1:-}" != "" ]; then
  DEVICE_FLAG="-s $1"
fi

echo "=== Step 1: Locate DJI Fly APK on device ==="
APK_PATHS=$($ADB $DEVICE_FLAG shell pm path dji.go.v5 2>&1)
echo "$APK_PATHS"

mkdir -p "$APK_DIR"

echo ""
echo "=== Step 2: Pull APK(s) from device ==="
i=0
for line in $APK_PATHS; do
  path="${line#package:}"
  filename="dji_fly_$i.apk"
  echo "Pulling $path -> $APK_DIR/$filename"
  $ADB $DEVICE_FLAG pull "$path" "$APK_DIR/$filename"
  i=$((i + 1))
done

echo ""
echo "=== Step 3: Decompile with jadx ==="
rm -rf "$OUT_DIR"
# Decompile the base APK (index 0) — split APKs can be added if needed
$JADX \
  --deobf \
  --threads-count 4 \
  --output-dir "$OUT_DIR" \
  "$APK_DIR"/dji_fly_*.apk

echo ""
echo "=== Done! Decompiled source is in: $OUT_DIR ==="
echo "Search for waypoint logic:"
echo "  grep -r 'waypoint' $OUT_DIR/sources/ --include='*.java' -l | head -20"
echo "  grep -r 'kmzTemp' $OUT_DIR/sources/ --include='*.java' -l"
echo "  grep -r 'WaypointMission' $OUT_DIR/sources/ --include='*.java' -l | head -20"

#!/usr/bin/env bash
set -euo pipefail

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ICON="${REPO_ROOT}/src/icon.png"
RES_DIR="${REPO_ROOT}/android/app/src/main/res"

if [ ! -f "$SOURCE_ICON" ]; then
  echo "Error: Source icon not found at $SOURCE_ICON" >&2
  exit 1
fi

MAGICK_CMD="magick"
if ! command -v magick >/dev/null 2>&1; then
  if command -v convert >/dev/null 2>&1; then
    MAGICK_CMD="convert"
  else
    if [ -f "${RES_DIR}/mipmap-xxxhdpi/ic_launcher.png" ]; then
      echo "Notice: ImageMagick (magick/convert) not found, but launcher icons already exist in ${RES_DIR}. Skipping generation."
      exit 0
    fi
    echo "Error: ImageMagick (magick/convert) not found and no pre-generated icons exist." >&2
    exit 1
  fi
fi

echo "==> Generating compressed Android launcher icons from src/icon.png..."

mkdir -p "$RES_DIR"

declare -A DENSITIES=(
  ["mipmap-mdpi"]="48"
  ["mipmap-hdpi"]="72"
  ["mipmap-xhdpi"]="96"
  ["mipmap-xxhdpi"]="144"
  ["mipmap-xxxhdpi"]="192"
)

declare -A FOREGROUND_DENSITIES=(
  ["mipmap-mdpi"]="108"
  ["mipmap-hdpi"]="162"
  ["mipmap-xhdpi"]="216"
  ["mipmap-xxhdpi"]="324"
  ["mipmap-xxxhdpi"]="432"
)

for DENSITY in "${!DENSITIES[@]}"; do
  SIZE="${DENSITIES[$DENSITY]}"
  TARGET_DIR="${RES_DIR}/${DENSITY}"
  mkdir -p "$TARGET_DIR"

  # Standard square icon
  $MAGICK_CMD "$SOURCE_ICON" -resize "${SIZE}x${SIZE}^" -gravity center -extent "${SIZE}x${SIZE}" -strip -quality 85 "${TARGET_DIR}/ic_launcher.png"

  # Round icon (applied circular mask)
  $MAGICK_CMD "$SOURCE_ICON" -resize "${SIZE}x${SIZE}^" -gravity center -extent "${SIZE}x${SIZE}" \
    \( +clone -alpha extract -draw "fill black polygon 0,0 0,$SIZE $SIZE,$SIZE $SIZE,0 fill white circle $(($SIZE/2)),$(($SIZE/2)) $(($SIZE/2)),0" \) \
    -alpha off -compose CopyOpacity -composite -strip -quality 85 "${TARGET_DIR}/ic_launcher_round.png"
done

# Adaptive foreground icons
for DENSITY in "${!FOREGROUND_DENSITIES[@]}"; do
  SIZE="${FOREGROUND_DENSITIES[$DENSITY]}"
  TARGET_DIR="${RES_DIR}/${DENSITY}"
  mkdir -p "$TARGET_DIR"
  $MAGICK_CMD "$SOURCE_ICON" -resize "${SIZE}x${SIZE}^" -gravity center -extent "${SIZE}x${SIZE}" -strip -quality 85 "${TARGET_DIR}/ic_launcher_foreground.png"
done

# Generate a high-res 512x512 play store / web icon
mkdir -p "${REPO_ROOT}/android/app/src/main"
$MAGICK_CMD "$SOURCE_ICON" -resize 512x512^ -gravity center -extent 512x512 -strip -quality 85 "${REPO_ROOT}/android/app/src/main/ic_launcher-web.png"

echo "==> Successfully generated all Android icons in $RES_DIR"

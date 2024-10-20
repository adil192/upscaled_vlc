#!/usr/bin/bash

function help() {
  echo "To play a video file:"
  echo "    $0 /path/to/video.mp4"
  echo "To view this help message:"
  echo "    $0 --help"
  echo "To check if all dependencies are installed:"
  echo "    $0 --check-dependencies"
}

function check_args() {
  if [ "$#" -ne 1 ]; then
    help
    exit 1
  fi
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    help
    exit 0
  fi
  if [ "$1" = "-c" ] || [ "$1" = "--check-dependencies" ]; then
    check_dependencies
    echo "All dependencies are installed :)"
    exit 0
  fi
  if [ ! -f "$1" ]; then
    echo "File not found: $1"
    exit 2
  fi
}

function check_dependencies() {
  if [ ! -x "$(command -v ffprobe)" ]; then
    echo "ffprobe not found"
    echo "Try \`sudo dnf install ffmpeg\` or similar"
    exit 10
  fi
  if [ ! -x "$(command -v gamescope)" ]; then
    echo "gamescope not found"
    echo "Try \`sudo dnf install gamescope\` or similar"
    exit 11
  fi
  if [ ! -x "$(command -v xdpyinfo)" ]; then
    echo "xdpyinfo not found"
    echo "Try \`sudo dnf install xdpyinfo\` or similar"
    exit 12
  fi
  if [ ! -x "$(command -v vlc)" ]; then
    echo "vlc not found"
    echo "Try \`sudo dnf install vlc\` or similar"
    exit 13
  fi
}

check_args "$@"
check_dependencies

VIDEO_FILE="$1"

IFS=x read VIDEO_WIDTH VIDEO_HEIGHT <<< $(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$VIDEO_FILE")
echo "Video resolution: ${VIDEO_WIDTH}x${VIDEO_HEIGHT}"

# On multi-monitor setups, use the highest resolution monitor
SCREEN_WIDTH=0
SCREEN_HEIGHT=0
for line in $(xrandr | grep "\*" | cut -d" " -f4); do
  IFS=x read w h <<< $line
  if [ $w -gt $SCREEN_WIDTH ] || [ $h -gt $SCREEN_HEIGHT ]; then
    SCREEN_WIDTH=$w
    SCREEN_HEIGHT=$h
  fi
done
if [ $SCREEN_WIDTH -eq 0 ] || [ $SCREEN_HEIGHT -eq 0 ]; then
  echo "Failed to detect screen resolution, using 1920x1080..."
  echo "Please file a bug report at https://github.com/adil192/upscaled_vlc/issues"
  SCREEN_WIDTH=1920
  SCREEN_HEIGHT=1080
fi
echo "Screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

# Set VIDEO_WIDTH to match screen's aspect ratio
VIDEO_WIDTH=$((VIDEO_HEIGHT * SCREEN_WIDTH / SCREEN_HEIGHT))
echo "Adjusted video resolution: ${VIDEO_WIDTH}x${VIDEO_HEIGHT}"

if [ $VIDEO_WIDTH -lt $SCREEN_WIDTH ] || [ $VIDEO_HEIGHT -lt $SCREEN_HEIGHT ]; then
  echo "Enabling upscaling..."
  gamescope \
    -w "$VIDEO_WIDTH" -h "$VIDEO_HEIGHT" \
    -W "$SCREEN_WIDTH" -H "$SCREEN_HEIGHT" \
    -F fsr \
    -f \
    -- vlc -f "$VIDEO_FILE"
else
  echo "Skipping upscaling, using VLC as-is..."
  vlc -f "$VIDEO_FILE"
fi

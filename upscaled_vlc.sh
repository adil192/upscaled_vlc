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

# gamescope may have issues with Nvidia GPUs, and needs to use the sdl backend.
# This might no longer be the case, but I don't use Nvidia anymore so can't test.
# Returns 0 (true) if an Nvidia GPU is detected, 1 (false) otherwise.
function has_nvidia_gpu() {
  lspci | grep -Ei 'VGA|3D|2D' | grep -qi nvidia
}

check_args "$@"
check_dependencies

VIDEO_FILE="$1"

IFS=x read VIDEO_WIDTH VIDEO_HEIGHT <<< $(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$VIDEO_FILE")
if [ -z "$VIDEO_WIDTH" ] || [ -z "$VIDEO_HEIGHT" ]; then
  echo "Failed to detect video resolution, defaulting to 1920x1080. Please file a bug report at https://github.com/adil192/upscaled_vlc/issues"
  VIDEO_WIDTH=1920
  VIDEO_HEIGHT=1080
fi
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

# Increase video resolution to fit aspect ratio
VIDEO_ASPECT_RATIO=$(bc <<< "scale=10; $VIDEO_WIDTH / $VIDEO_HEIGHT")
SCREEN_ASPECT_RATIO=$(bc <<< "scale=10; $SCREEN_WIDTH / $SCREEN_HEIGHT")
if [ $(bc <<< "$VIDEO_ASPECT_RATIO > $SCREEN_ASPECT_RATIO") -eq 1 ]; then
  echo "Video is wider than screen, adjusting video height..."
  VIDEO_HEIGHT=$(bc <<< "scale=0; $VIDEO_WIDTH / $SCREEN_ASPECT_RATIO")
  echo "Adjusted video resolution: ${VIDEO_WIDTH}x${VIDEO_HEIGHT}"
elif [ $(echo "$VIDEO_ASPECT_RATIO < $SCREEN_ASPECT_RATIO" | bc) -eq 1 ]; then
  echo "Video is taller than screen, adjusting video width..."
  VIDEO_WIDTH=$(bc <<< "scale=0; $VIDEO_HEIGHT * $SCREEN_ASPECT_RATIO")
  echo "Adjusted video resolution: ${VIDEO_WIDTH}x${VIDEO_HEIGHT}"
fi

BACKEND_ARG=""
if has_nvidia_gpu; then
  BACKEND_ARG="--backend sdl"
fi

if [ $VIDEO_WIDTH -lt $SCREEN_WIDTH ] || [ $VIDEO_HEIGHT -lt $SCREEN_HEIGHT ]; then
  echo "Enabling upscaling..."
  gamescope \
    -w "$VIDEO_WIDTH" -h "$VIDEO_HEIGHT" \
    -W "$SCREEN_WIDTH" -H "$SCREEN_HEIGHT" \
    ${BACKEND_ARG} \
    -F fsr \
    -f \
    -- vlc -f "$VIDEO_FILE"
else
  echo "Skipping upscaling, using VLC as-is..."
  vlc -f "$VIDEO_FILE"
fi

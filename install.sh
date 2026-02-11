#!/usr/bin/bash
set -e

SYMLINK=0
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Usage: $0"
  echo "To view this help message:"
  echo "    $0 --help"
  echo "To symlink instead of copying the files:"
  echo "    $0 -s"
  exit 0
elif [ "$1" = "-s" ] || [ "$1" = "--symlink" ]; then
  SYMLINK=1
fi

if ! command -v ffprobe   >/dev/null 2>&1 ||
   ! command -v gamescope >/dev/null 2>&1 ||
   ! command -v xdpyinfo  >/dev/null 2>&1 ||
   ! command -v vlc       >/dev/null 2>&1; then

  echo "Some dependencies are missing, installing them now..."

  if command -v apt >/dev/null 2>&1; then
    sudo apt install -y ffmpeg gamescope x11-utils vlc
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y ffmpeg gamescope xdpyinfo vlc
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --needed ffmpeg gamescope xorg-xdpyinfo vlc
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y ffmpeg gamescope xdpyinfo vlc
  else
    echo "Unrecognized package manager."
    echo "Please install these yourself: ffmpeg gamescope xdpyinfo vlc"
    exit 1
  fi
fi

PROJECT_DIR=$(pwd)
if [ ! -f "$PROJECT_DIR/upscaled_vlc.sh" ]; then
  echo "Installing from GitHub"
  TMPDIR=$(mktemp -d)
  git clone https://github.com/adil192/upscaled_vlc "$TMPDIR/upscaled_vlc"
  PROJECT_DIR="$TMPDIR/upscaled_vlc"
  SYMLINK=0 # Don't symlink to temp dir
else
  echo "Installing from local files"
fi

function cp_or_symlink() {
  if [ $SYMLINK -eq 1 ]; then
    echo "ln -sf $@"
    ln -sf "$@"
  else
    echo "cp $@"
    cp "$@"
  fi
}

# Install executable script
mkdir -p ~/.local/bin/
cp_or_symlink "$PROJECT_DIR/upscaled_vlc.sh" ~/.local/bin/
chmod +x ~/.local/bin/upscaled_vlc.sh

# Install icon
mkdir -p ~/.local/share/icons/hicolor/scalable/apps/
cp_or_symlink "$PROJECT_DIR/com.adilhanney.upscaled_vlc.svg" ~/.local/share/icons/hicolor/scalable/apps/

# Install desktop entry
mkdir -p ~/.local/share/applications/
cp_or_symlink "$PROJECT_DIR/com.adilhanney.upscaled_vlc.desktop" ~/.local/share/applications/
# Use absolute path for executable in desktop entry
sed -i "s|Exec=upscaled_vlc.sh|Exec=$HOME/.local/bin/upscaled_vlc.sh|" ~/.local/share/applications/com.adilhanney.upscaled_vlc.desktop
# Let system know about the new desktop entry
update-desktop-database ~/.local/share/applications

rm -rf "$TMPDIR"

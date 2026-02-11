# upscaled_vlc

An easy-to-use wrapper around the [VLC media player](https://www.videolan.org/vlc/)
that enables real-time upscaling on Linux.

## Install

1. Install the dependencies for your distro:

    ```bash
    # Fedora / RHEL
    sudo dnf install ffmpeg xdpyinfo vlc gamescope

    # Debian / Ubuntu / Pop!_OS
    sudo apt install ffmpeg x11-utils vlc gamescope

    # Arch Linux
    sudo pacman -S ffmpeg xorg-xdpyinfo vlc gamescope
    ```

2. Install upscaled_vlc:

    ```bash
    wget -O - https://raw.githubusercontent.com/adil192/upscaled_vlc/main/install.sh | bash
    ```

## Usage

Simply open a video from your file manager in the Upscaled VLC app.

<img src="https://github.com/user-attachments/assets/7b722176-e2b8-417b-922f-4ab7b3b42c0c" width="436" height="249" alt="The Open File window showing Upscaled VLC as an option.">

## Uninstall

```bash
wget -O - https://raw.githubusercontent.com/adil192/upscaled_vlc/main/uninstall.sh | bash
```

## Disclaimer

This project is not affiliated with VideoLAN, VLC, Valve, Steam, or gamescope.

If you're using NixOS, you may wish to use the similar project
[philippedev101/upscaled_vlc](https://github.com/philippedev101/upscaled_vlc)
written in Nushell instead.

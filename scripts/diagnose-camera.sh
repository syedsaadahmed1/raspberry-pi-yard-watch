#!/usr/bin/env bash
set -Eeuo pipefail

camera_device="${1:-/dev/video0}"
if [[ ! -c "$camera_device" ]]; then
  printf '%s is not a camera character device.\n' "$camera_device" >&2
  exit 1
fi

printf 'Camera: %s\n' "$camera_device"
if command -v v4l2-ctl >/dev/null 2>&1; then
  v4l2-ctl --all --device "$camera_device"
  v4l2-ctl --list-formats-ext --device "$camera_device"
else
  printf 'v4l2-ctl is missing. Install it with: sudo apt install v4l-utils\n' >&2
fi

if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -hide_banner -f v4l2 -list_formats all -i "$camera_device" || true
else
  printf 'ffmpeg is missing; optional host-side format probe skipped.\n' >&2
fi

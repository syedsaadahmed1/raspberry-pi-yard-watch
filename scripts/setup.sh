#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

if [[ "$(uname -m)" != "aarch64" ]]; then
  printf 'Warning: expected a 64-bit Raspberry Pi host (aarch64); found %s.\n' "$(uname -m)"
fi

for command_name in docker; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing %s. Install Docker Engine with the Compose plugin first.\n' "$command_name" >&2
    exit 1
  fi
done

if ! docker compose version >/dev/null 2>&1; then
  printf 'Docker Compose plugin is missing.\n' >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  cp .env.example .env
  printf 'Created .env; review timezone and camera path.\n'
fi

if [[ ! -f config/config.yml ]]; then
  cp config/config.example.yml config/config.yml
  printf 'Created config/config.yml; customize the yard polygon and camera mode.\n'
fi

mkdir -p storage
chmod 700 config storage

camera_device="$(sed -n 's/^CAMERA_DEVICE=//p' .env | tail -n 1)"
camera_device="${camera_device:-/dev/video0}"
if [[ ! -c "$camera_device" ]]; then
  printf 'Warning: %s is not currently a character device.\n' "$camera_device"
fi

if ! id -nG | tr ' ' '\n' | grep -qx video; then
  printf 'Warning: %s is not in the video group; device access may fail.\n' "$USER"
  printf 'Run: sudo usermod -aG video %q  (then log out and back in)\n' "$USER"
fi

docker compose config --quiet
printf '\nSetup complete. Next: edit .env and config/config.yml, then run:\n'
printf '  ./scripts/validate.sh\n  docker compose up -d\n'

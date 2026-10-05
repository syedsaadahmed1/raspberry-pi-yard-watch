#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"
failures=0

check_file() {
  if [[ -f "$1" ]]; then
    printf 'ok: %s\n' "$1"
  else
    printf 'missing: %s\n' "$1" >&2
    failures=$((failures + 1))
  fi
}

check_file .env
check_file config/config.yml

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  if docker compose config --quiet; then
    printf 'ok: Docker Compose configuration\n'
  else
    failures=$((failures + 1))
  fi
else
  printf 'missing: Docker with Compose plugin\n' >&2
  failures=$((failures + 1))
fi

if [[ -f .env ]]; then
  camera_device="$(sed -n 's/^CAMERA_DEVICE=//p' .env | tail -n 1)"
  camera_device="${camera_device:-/dev/video0}"
  if [[ -c "$camera_device" ]]; then
    printf 'ok: camera device %s\n' "$camera_device"
  else
    printf 'missing: camera character device %s\n' "$camera_device" >&2
    failures=$((failures + 1))
  fi
fi

if [[ -f config/config.yml ]] && grep -q '0.001,0.001,0.999,0.001' config/config.yml; then
  printf 'warning: yard zone still uses the full-frame bootstrap polygon\n'
fi

if git ls-files --error-unmatch .env config/config.yml >/dev/null 2>&1; then
  printf 'unsafe: a local configuration file is tracked by Git\n' >&2
  failures=$((failures + 1))
else
  printf 'ok: local configuration is not tracked\n'
fi

if (( failures > 0 )); then
  printf 'Validation failed with %d issue(s).\n' "$failures" >&2
  exit 1
fi
printf 'Validation passed.\n'

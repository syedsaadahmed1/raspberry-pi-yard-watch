#!/usr/bin/env bash
set -Eeuo pipefail

failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }

printf 'Pi Yard Watch — Phase 1 readiness\n\n'

architecture="$(uname -m)"
if [[ "$architecture" == "aarch64" ]]; then
  pass "64-bit ARM host ($architecture)"
else
  fail "expected aarch64 Raspberry Pi host; found $architecture"
fi

if [[ -r /proc/device-tree/model ]]; then
  model="$(tr -d '\0' </proc/device-tree/model)"
  if [[ "$model" == *"Raspberry Pi 5"* ]]; then
    pass "$model"
  else
    warn "target model is Raspberry Pi 5; detected: $model"
  fi
else
  warn "cannot read Raspberry Pi model from /proc/device-tree/model"
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  pass "operating system: ${PRETTY_NAME:-unknown}"
else
  fail "cannot read /etc/os-release"
fi

memory_kib="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
if [[ -n "$memory_kib" && "$memory_kib" -ge 3800000 ]]; then
  pass "memory: $((memory_kib / 1024)) MiB"
else
  warn "less than approximately 4 GB RAM detected"
fi

for command_name in git v4l2-ctl ffmpeg docker lsblk findmnt; do
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "command available: $command_name"
  else
    fail "missing command: $command_name"
  fi
done

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    pass "Docker daemon is reachable by $(id -un)"
  else
    fail "Docker daemon is not reachable by $(id -un)"
  fi
  if docker compose version >/dev/null 2>&1; then
    pass "Docker Compose plugin is available"
  else
    fail "Docker Compose plugin is missing"
  fi
fi

if compgen -G '/dev/video*' >/dev/null; then
  pass "video devices: $(printf '%s ' /dev/video*)"
else
  fail "no /dev/video* devices found; connect the webcam"
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_source="$(findmnt -no SOURCE --target "$repo_dir" 2>/dev/null || true)"
repo_target="$(findmnt -no TARGET --target "$repo_dir" 2>/dev/null || true)"
if [[ -n "$repo_source" ]]; then
  pass "repository filesystem: $repo_source mounted at $repo_target"
else
  fail "could not resolve repository filesystem mount"
fi

available_kib="$(df -Pk "$repo_dir" | awk 'NR==2 {print $4}')"
if [[ -n "$available_kib" && "$available_kib" -ge 52428800 ]]; then
  pass "at least 50 GiB available on repository filesystem"
else
  warn "less than 50 GiB available on repository filesystem"
fi

if git -C "$repo_dir" diff --quiet && git -C "$repo_dir" diff --cached --quiet; then
  pass "Git worktree is clean"
else
  warn "Git worktree has local changes"
fi

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
if (( failures > 0 )); then
  exit 1
fi

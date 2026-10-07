# Project roadmap

This roadmap tracks the path from a shareable configuration repository to a
reliable yard-monitoring installation. A phase is complete only when its exit
criteria are verified on the target hardware.

## Current status

- [x] Phase 0 — Repository foundation
- [x] Phase 1 — Raspberry Pi host preparation
- [x] Phase 2 — Webcam characterization
- [ ] Phase 3 — First Frigate deployment **(current)**
- [ ] Phase 4 — Yard-zone and detection tuning
- [ ] Phase 5 — Performance and retention testing
- [ ] Phase 6 — Phone notifications
- [ ] Phase 7 — Security and reliability hardening
- [ ] Phase 8 — Publish measured results and v1.0

## Phase 0 — Repository foundation

Delivered:

- public GitHub repository with a documented architecture;
- Docker Compose and Frigate configuration templates;
- setup, validation, and camera-diagnostics scripts;
- notification, security, Pi deployment, and GMKtec offload guides;
- CI checks and secret-safe ignore rules.

Exit criteria: repository is public, `main` is pushed, and local `main` tracks
`origin/main`. **Complete.**

## Phase 1 — Raspberry Pi host preparation

Tasks:

- install a supported 64-bit Raspberry Pi OS on the Pi 5;
- update OS packages and firmware through the distribution;
- connect the 128 GB SSD, USB webcam, wired network where possible, and an
  adequate Pi 5 power supply;
- identify the SSD filesystem and mount it persistently by UUID;
- install Git, `v4l-utils`, FFmpeg, Docker Engine, and Docker Compose;
- clone this repository onto the SSD;
- run `./scripts/phase1-readiness.sh` and resolve failures.

Exit criteria:

- host reports `aarch64` and has adequate free memory and storage;
- SSD mount survives a reboot;
- Docker and `docker compose` work for the deployment user;
- webcam character devices are visible;
- repository is cloned on the SSD with a clean `main` branch.

Status: **Complete.** Verified on a Raspberry Pi 5 with 8 GB RAM, Debian 13
(64-bit), a 128 GB NVMe root filesystem, Docker Engine and Compose, and the USB
webcam attached. The host passed the readiness audit before and after a kernel
update and controlled reboot.

## Phase 2 — Webcam characterization

- enumerate stable `/dev/v4l/by-id` paths and supported V4L2 modes;
- test MJPEG/H.264/YUYV resolutions and frame rates;
- select a stable 720p-or-better mode without USB or power instability;
- update local `.env` and `config/config.yml` for the actual camera.

Exit criteria: the chosen device path and video mode work after a reboot and do
not expose machine-specific identifiers in Git.

Status: **Complete.** The attached USB webcam exposes a stable by-ID path and
supports MJPEG at 1280×720 and 30 FPS. That mode passed a live capture test after
the Phase 1 reboot. Its machine-specific path is stored only in the ignored local
`.env` file.

## Phase 3 — First Frigate deployment

- generate local configuration and validate Compose;
- pull and start Frigate;
- verify authenticated UI, live view, recording, SSD writes, and restart policy;
- confirm the service returns after a host reboot.

Exit criteria: stable video and recording for at least several hours with no
repeating FFmpeg, permission, storage, or restart errors.

## Phase 4 — Yard-zone and detection tuning

- replace the full-frame bootstrap zone with the real yard polygon;
- exclude public and neighboring areas;
- test person entry at multiple distances, angles, and lighting conditions;
- tune motion and object filters using evidence from the debug view.

Exit criteria: useful person events are retained only after entering the yard
zone, with acceptable false positives and missed detections.

## Phase 5 — Performance and retention testing

- collect CPU, RAM, temperature, detector latency, dropped-frame, and disk data;
- test daylight, darkness, rain/wind, and ordinary household activity;
- measure actual storage consumption and adjust retention;
- decide whether Pi-only operation meets the target.

Exit criteria: a documented multi-day baseline and an evidence-based decision to
keep Pi-only processing, add an accelerator, or proceed to GMKtec offload.

## Phase 6 — Phone notifications

- choose native Frigate WebPush or MQTT/Home Assistant;
- configure HTTPS/VPN access without internet port forwarding;
- test snapshot updates, zone filters, cooldowns, and away-from-home delivery.

Exit criteria: prompt, actionable phone alerts with no duplicate storm and no
direct exposure of Frigate or RTSP services to the internet.

## Phase 7 — Security and reliability hardening

- restrict firewall rules and remove unused ports;
- establish OS, Docker, and Frigate update procedures;
- implement encrypted configuration backup and test restoration;
- test power-loss, camera disconnect, network interruption, and disk-full cases;
- add service, temperature, and disk-capacity monitoring.

Exit criteria: documented recovery procedures and successful failure/recovery
tests appropriate to the deployment's threat model.

## Phase 8 — Publish results and v1.0

- publish sanitized hardware details and measured performance;
- document the tested webcam mode and 128 GB retention results;
- add troubleshooting findings and safe example screenshots if useful;
- tag a reproducible `v1.0.0` release.

Exit criteria: another Raspberry Pi 5 owner can reproduce the proven setup from
the repository without relying on private identifiers or undocumented steps.

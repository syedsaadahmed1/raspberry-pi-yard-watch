# Raspberry Pi 5 deployment

## 1. Prepare the host

Use a 64-bit Raspberry Pi OS release and update it before deployment. Mount the
SSD at a stable path (for example `/srv/pi-yard-watch`) using its filesystem UUID,
then clone the repository there. Avoid placing recordings on the microSD card.

After cloning, run the Phase 1 host audit:

```bash
./scripts/phase1-readiness.sh
```

Resolve all failures before continuing. Warnings identify items that require a
human decision or may be acceptable for a development-only host.

Install Docker Engine and its Compose plugin from Docker's current Debian
instructions. Add your user to the `docker` group only if you accept that members
of that group effectively have root-equivalent control of the host.

Useful host packages:

```bash
sudo apt update
sudo apt install -y git v4l-utils ffmpeg
```

Use a suitable Pi 5 power supply. A webcam and bus-powered SSD can expose marginal
power or USB-bandwidth issues; a powered hub or powered SSD enclosure may help.

## 2. Identify a stable camera device

```bash
v4l2-ctl --list-devices
./scripts/diagnose-camera.sh /dev/video0
ls -l /dev/v4l/by-id/
```

`/dev/video0` can change after reboots. Prefer a `/dev/v4l/by-id/...` symlink in
`.env` when one exists. This machine-specific path belongs only in `.env`.

Confirm the webcam supports the template's MJPEG 1280×720 at 15 FPS. If it does
not, edit the `go2rtc` source, `detect.width`, and `detect.height` together. YUYV
at high resolution consumes far more USB bandwidth than MJPEG.

## 3. Configure and start

```bash
cp .env.example .env
./scripts/setup.sh
editor .env
editor config/config.yml
./scripts/validate.sh
docker compose pull
docker compose up -d
docker compose logs -f frigate
```

Browse to `https://PI_ADDRESS:8971`. Retrieve the initial administrator password
from `docker compose logs frigate`, sign in, and change it. Do not expose port
5000: it is the internal unauthenticated API. Ports 8554 and 8555 are intended for
LAN streaming; remove those mappings if no other client needs them.

## 4. Draw the real yard zone

In Frigate, open **Settings → Camera configuration → Masks / Zones**, select
`yard_camera`, and redraw `yard`. Use the debug view to check entry behavior. An
object is considered inside using the bottom-center of its bounding box, so draw
the boundary along the ground plane. Exclude sidewalks, neighboring property,
roads, reflective windows, and moving vegetation where possible.

The template requires the zone for review alerts, detections, and snapshots.
Recordings retain motion briefly even outside the zone to aid troubleshooting.

## 5. Measure before optimizing

Let the stack run through daylight and darkness, then inspect **System Metrics**:

- detector inference speed and skipped/dropped frames
- total CPU and memory pressure
- camera and host temperatures (`vcgencmd measure_temp` when available)
- SSD utilization (`df -h`) and Docker logs
- false positives and missed entries at the yard boundary

Do not copy Pi 4 `/dev/video11` acceleration examples into a Pi 5 deployment
without verifying the device and logs. The initial configuration intentionally
does not specify `hwaccel_args`. Tune detection FPS/resolution first; offload if
sustained CPU or thermal load is unacceptable.

## 6. Back up configuration

Stop the service for a consistent database backup. Back up `.env`, `config/`, and
any recordings you truly need to encrypted storage. These contain credentials,
camera-derived metadata, or private imagery and must not be committed.

```bash
docker compose stop
sudo tar -C /srv -czf /secure/backup/pi-yard-watch-config.tgz \
  pi-yard-watch/.env pi-yard-watch/config
docker compose start
```

Adapt paths to your host. Test restoration periodically.

## Troubleshooting

- `Permission denied` on the camera: inspect device ownership, add the operator
  to `video`, log in again, and confirm the Compose device mapping.
- No video: compare the go2rtc source with `diagnose-camera.sh` output. Try a
  supported size, frame rate, and format.
- `Bus error`: check logs, process limits, and shared memory. One 720p camera fits
  the provided 128 MB with headroom, but increase it if diagnostics justify it.
- High load: lower camera input FPS, detect FPS, or resolution; avoid unnecessary
  transcoding; then consider the GMKtec or a supported accelerator.
- SSD fills: reduce motion/event retention and inspect unexpected constant motion.

Current upstream references: [installation](https://docs.frigate.video/frigate/installation/),
[USB cameras](https://docs.frigate.video/configuration/camera_specific/#usb-cameras-aka-webcams),
and [getting started](https://docs.frigate.video/guides/getting_started/).

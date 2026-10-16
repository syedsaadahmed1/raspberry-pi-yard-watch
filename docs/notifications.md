# Phone notifications and integration hooks

Recordings work without MQTT. Choose one notification path after the core camera
and detection pipeline is reliable.

## Native Frigate WebPush

Frigate supports encrypted browser WebPush. It requires:

1. access to Frigate through trusted HTTPS while signed in;
2. outbound internet access from Frigate to the browser vendor's push service;
3. a supported phone browser and notification permission.

Configure it in **Settings → Notifications**, supplying your email there rather
than in this repository, then enable notifications for `yard_camera`. Install the
site as a home-screen web app if appropriate for the phone. Use a VPN plus a
trusted reverse proxy for remote access; do not port-forward Frigate directly.

The email becomes local runtime configuration under `config/` and is ignored by
Git. Native notification delivery involves the browser vendor's push service,
even though video and detection remain local.

See Frigate's current [notification documentation](https://docs.frigate.video/configuration/notifications/).

### Private HTTPS with Tailscale

One tested option is Tailscale Serve. Install Tailscale on the Pi and phone,
join both to the same tailnet, and expose Frigate's authenticated HTTPS port
only inside that tailnet:

```bash
sudo tailscale up --hostname=raspberrypi-yard-watch
sudo tailscale serve --https=8443 --bg https+insecure://127.0.0.1:8971
tailscale serve status
```

Open the resulting URL on the phone, using the actual MagicDNS name shown by
`tailscale serve status`:

```text
https://raspberrypi-yard-watch.example-tailnet.ts.net:8443/
```

Port `8443` is useful when another service, such as Pi-hole, already owns local
port `443`. Verify that the phone URL presents a publicly trusted certificate;
do not accept a certificate warning. Tailscale Serve remains tailnet-only and
does not require router port forwarding.

Enable WebPush in the ignored local `config/config.yml`. Do not put the real
email address in the repository:

```yaml
notifications:
  enabled: true
  email: "your-private-email@example.com"
  cooldown: 60

cameras:
  yard_camera:
    notifications:
      enabled: true
```

On Android, open the Tailscale HTTPS URL in Chrome, sign in to Frigate, then
enable the device under **Settings → Notifications**. Allow Chrome
notifications and consider installing the site as a home-screen app. Samsung
battery settings should not put Tailscale or Chrome into deep sleep.

The subscription is working when Frigate has a token for the signed-in user and
the push service accepts a test. If Google Firebase returns HTTP `404` or `410`,
the browser subscription has expired: disable notifications for that device,
clear that origin's site data/permissions, remove the expired server token, and
register again. Never publish WebPush endpoints, keys, the tailnet DNS suffix,
or the notification email.

## MQTT / Home Assistant hook

MQTT is optional but required by Frigate's Home Assistant integration. Run an
authenticated broker on the trusted LAN, then change the local, ignored
`config/config.yml`:

```yaml
mqtt:
  enabled: true
  host: 192.0.2.10
  port: 1883
  user: "{FRIGATE_MQTT_USER}"
  password: "{FRIGATE_MQTT_PASSWORD}"
```

Add `FRIGATE_MQTT_USER` and `FRIGATE_MQTT_PASSWORD` only to `.env`, and expose
them to the container under `environment` in a local Compose override that is
also ignored. Frigate only substitutes environment variables prefixed
`FRIGATE_`. Prefer Docker secrets if your deployment standard supports them.

For phone alerts, use the official Frigate Home Assistant notification blueprint
or build an automation from `frigate/reviews`. Review messages carry the IDs
needed to request the changing thumbnail/snapshot/clip and are preferred over
legacy event-only triggers. Filter for camera `yard_camera`, label `person`, and
zone `yard` as defense in depth.

Relevant topics:

- `frigate/reviews` — recommended notification change feed
- `frigate/events` — tracked-object lifecycle hook
- `frigate/yard/person` — count in the yard zone
- `frigate/yard_camera/person/snapshot` — current JPEG snapshot

Treat MQTT as a private control plane: require credentials, restrict listeners to
the LAN/VPN, use TLS across untrusted networks, and give automation clients only
the topic permissions they need.

References: [MQTT topics](https://docs.frigate.video/integrations/mqtt/) and
[Home Assistant notifications](https://docs.frigate.video/guides/ha_notifications/).

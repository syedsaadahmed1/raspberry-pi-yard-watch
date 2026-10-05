# Security and privacy checklist

## Network

- Keep Frigate and RTSP on a trusted, segmented LAN. Do not expose ports 8971,
  8554, 8555, or especially the unauthenticated internal port 5000 to the internet.
- Use a VPN for remote access. If using a reverse proxy, terminate trusted HTTPS,
  proxy to authenticated port 8971, and keep the upstream private.
- Remove 8554/8555 mappings if no LAN client needs them. go2rtc restreams are not
  authenticated by default unless configured.
- Enable a host firewall and allow management only from expected subnets.
- Apply Raspberry Pi OS, Docker, Frigate, and reverse-proxy security updates.

## Credentials and repository hygiene

- Use unique administrator, MQTT, VPN, and reverse-proxy credentials.
- Never commit `.env`, `config/config.yml`, Compose overrides containing secrets,
  Frigate databases, logs, snapshots, recordings, IPs, MAC addresses, serials, or
  stable `/dev/v4l/by-id` paths.
- Review `git diff --cached` before every push. Consider a secret scanner in CI.
- Treat backups as sensitive: encrypt them and test access controls and restores.

## Physical and host security

- Limit SSH to key authentication, disable unused services, and protect the Pi
  and SSD from theft or tampering.
- Docker-group membership is root-equivalent. Grant it sparingly.
- Consider full-disk or data-volume encryption if stolen hardware is in scope;
  plan how unattended boot and power recovery should work.
- Use a reliable power supply and clean shutdown/UPS strategy where outages are
  common. Filesystem damage can destroy both evidence and configuration.

## Camera privacy and legal considerations

- Aim and crop the camera to capture only the property and approach that need
  protection. Exclude neighboring windows, yards, sidewalks, and roads.
- Use zones and masks to minimize collection; turn off audio unless it is needed
  and lawful. The sample config does not request audio.
- Keep the shortest retention that meets the real need. Regularly confirm cleanup.
- Restrict Frigate accounts and exports. Audit who can view or download footage.
- Check local laws, lease/HOA rules, notice requirements, audio-consent rules, and
  expectations of household members and visitors. This project is not legal advice.

## Incident response

If exposure is suspected, disconnect external access, rotate all credentials,
preserve relevant logs, update affected components, and review repository history
for accidentally committed secrets. Removing a secret from the latest commit is
not enough; rotate it even if Git history is later rewritten.

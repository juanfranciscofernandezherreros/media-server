# Security policy

This project is intended for a private home media server. The recommended deployment keeps the router closed and exposes services only through private networks.

## Supported security model

The expected model is:

```text
Router                 → no inbound port forwarding
Remote access          → Tailscale
Jellyfin sharing       → Tailscale + individual Jellyfin users
Deluge outbound traffic→ Gluetun + NordVPN
Administration panels  → localhost only
Observability          → localhost only
```

Do not expose administrative interfaces directly to the public Internet.

## Services that must stay private

Keep these services private unless you intentionally publish them behind a hardened private access layer:

- Sonarr (`8989`)
- Radarr (`7878`)
- Prowlarr (`9696`)
- Bazarr (`6767`)
- Jellyseerr (`5055`)
- Deluge Web UI (`8112`)
- Deluge daemon/thin-client port (`58846`)
- BitTorrent ports (`6881/tcp`, `6881/udp`)
- Grafana, Prometheus, Loki, Alloy and cAdvisor
- Samba/SMB
- SSH or host administration

Jellyfin should be shared through Tailscale for the private deployment. If you later publish Jellyfin publicly, use HTTPS, strong passwords, separate Jellyfin users, monitoring, and a clear rollback plan.

## Secrets and private data

Do not commit:

- `.env`
- NordVPN credentials
- Tailscale state
- Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, Jellyseerr or Deluge configuration databases
- API keys
- Grafana passwords
- logs containing private paths, usernames, IP addresses or tokens
- downloaded files or media libraries

Runtime data belongs under ignored directories such as `docker/`, `downloads/`, `movies/`, `tv/` and `media/`.

## NordVPN credentials

The `NORDVPN_USER` and `NORDVPN_PASSWORD` values are NordVPN manual service credentials for OpenVPN. They are not your normal Nord Account email and password. Store them only in `.env`.

## Access control recommendations

Use Tailscale Grants or ACLs to enforce least privilege:

- Admin user: access to all private services.
- Jellyfin users: access only to `tcp:8096` on the media server.
- Guests: no access to Sonarr, Radarr, Prowlarr, Bazarr, Deluge, Samba or observability.

See `docs/tailscale-grants.md` for an example policy.

## Reporting issues

If you discover a security issue in the repository configuration, report it privately to the repository owner. Do not open a public issue containing credentials, private IPs, service tokens, logs with secrets, downloaded file names or personal data.

# Operations guide

Use this checklist after configuration changes, image updates, host restarts or network changes.

## Daily status

```powershell
docker compose ps
```

Expected state:

```text
gluetun      healthy
deluge       healthy
sonarr       healthy
radarr       healthy
prowlarr     healthy
bazarr       healthy
jellyseerr   healthy
jellyfin     healthy or running
tailscale    running
```

Some services may show `health: starting` immediately after restart. Wait a minute and run the command again.

## Verify NordVPN routing

Check Gluetun logs:

```powershell
docker compose logs --tail=100 gluetun
```

Expected signs:

```text
Initialization Sequence Completed
Public IP address is ...
```

Compare the host IP and Gluetun IP:

```powershell
curl.exe https://ipinfo.io/ip
docker exec gluetun wget -qO- https://ipinfo.io/ip
```

The values should differ. Deluge shares Gluetun's network, so Deluge uses Gluetun's VPN route.

## Verify Deluge integration

In Sonarr:

```text
Settings → Download Clients → Deluge → Test
Host: gluetun
Port: 8112
```

In Radarr:

```text
Settings → Download Clients → Deluge → Test
Host: gluetun
Port: 8112
```

If the test fails:

1. Confirm `gluetun` and `deluge` are healthy.
2. Confirm Deluge Web UI opens at `http://localhost:8112`.
3. Confirm the Deluge Web UI password is correct.
4. Confirm Sonarr/Radarr use `gluetun:8112`, not `deluge:58846`.
5. Restart the affected services:

```powershell
docker compose restart gluetun deluge sonarr radarr
```

## Verify Tailscale access

```powershell
docker exec tailscale tailscale status
```

From an authorized Tailscale device, open:

```text
http://media-server-share:8096
```

Or:

```text
http://100.x.x.x:8096
```

Do not use the public IP for the private deployment.

## Verify local-only panels

From the host, these should work:

```text
http://localhost:5055  Jellyseerr
http://localhost:6767  Bazarr
http://localhost:8989  Sonarr
http://localhost:7878  Radarr
http://localhost:9696  Prowlarr
http://localhost:8112  Deluge Web UI
```

From another LAN device without Tailscale, they should not be reachable if the ports are bound to `127.0.0.1`.

## Verify router exposure

The private deployment should have no port forwarding for:

```text
8096  Jellyfin
8112  Deluge Web UI
8989  Sonarr
7878  Radarr
9696  Prowlarr
6767  Bazarr
5055  Jellyseerr
58846 Deluge daemon
6881  BitTorrent TCP/UDP
3000  Grafana
9090  Prometheus
3100  Loki
8080  cAdvisor
22    SSH
445   SMB
```

If you need to test from outside the LAN, use a mobile hotspot or another external network. Testing the public IP from the same Wi-Fi may be affected by hairpin NAT and can be misleading.

## Backups

Back up at least:

```text
docker/jellyfin/
docker/sonarr/
docker/radarr/
docker/prowlarr/
docker/bazarr/
docker/jellyseerr/
docker/deluge/
docker/tailscale/
.env
docker-compose.yml
downloads/ only if you need in-progress downloads
movies/
tv/
```

Do not publish backups publicly. They may contain tokens, API keys, account data and private media paths.

## Safe update procedure

```powershell
docker compose ps
docker compose pull
docker compose up -d
docker compose ps
```

The media images are pinned by digest, so updating them requires intentionally changing the digest in `docker-compose.yml`.

For observability:

```powershell
docker compose -f docker-compose.observability.yml pull
docker compose -f docker-compose.observability.yml up -d
```

## Troubleshooting quick map

| Symptom | Likely cause | First check |
| --- | --- | --- |
| Sonarr/Radarr cannot connect to Deluge | Wrong host/port | Use `gluetun:8112` |
| Deluge works but IP is not VPN IP | Deluge not sharing Gluetun network | Check `network_mode: service:gluetun` |
| Deluge UI does not open | Gluetun or Deluge unhealthy | `docker compose ps` and Gluetun logs |
| Jellyfin unavailable remotely | Tailscale not connected or ACL blocks it | `tailscale status` |
| Admin panels unavailable from another PC | Expected localhost binding | Use host browser or Tailscale/proxy |
| Slow downloads | VPN server, peers, limits or disk | Test another nearby VPN region |

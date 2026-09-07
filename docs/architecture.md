# Architecture

This media server is designed as a private self-hosted stack with service-level network isolation.

## Goals

- Stream media through Jellyfin without exposing the full administration stack.
- Route Deluge traffic through NordVPN using Gluetun.
- Keep Sonarr, Radarr, Prowlarr, Bazarr, Jellyseerr and observability panels private.
- Avoid router port forwarding in the default deployment.
- Keep runtime configuration, credentials, downloads and media outside version control.

## High-level flow

```text
Jellyseerr ──> Sonarr ──┐
              Radarr ───┼──> Prowlarr
                         │
                         ▼
                  Gluetun :8112
                         │
                         ▼
                    Deluge
                         │
                         ▼
                 downloads/
                         │
               ┌─────────┴─────────┐
               ▼                   ▼
            movies/               tv/
               │                   │
               └─────────┬─────────┘
                         ▼
                      Jellyfin
                         │
                         ▼
                      Tailscale
```

## Network boundaries

### Public Internet

The default deployment does not require inbound router port forwarding. Deluge makes outbound connections through Gluetun/NordVPN. Remote users reach Jellyfin through Tailscale.

### Tailscale boundary

Jellyfin and Samba share the Tailscale network namespace. This lets authorized Tailscale users reach Jellyfin and the read-only SMB share without exposing them publicly.

Recommended access policy:

```text
Admin users   → all private services
Jellyfin users→ Jellyfin tcp:8096 only
Guests        → no administrative services
```

### Gluetun/NordVPN boundary

Deluge uses:

```yaml
network_mode: "service:gluetun"
```

This means Deluge does not have its own Docker network identity. Other containers reach Deluge through Gluetun.

Sonarr and Radarr should use:

```text
Host: gluetun
Port: 8112
```

Do not use `deluge:58846` for Sonarr/Radarr in this deployment.

### Localhost boundary

Administrative panels are bound to localhost:

```text
127.0.0.1:5055 → Jellyseerr
127.0.0.1:6767 → Bazarr
127.0.0.1:8989 → Sonarr
127.0.0.1:7878 → Radarr
127.0.0.1:9696 → Prowlarr
127.0.0.1:8112 → Deluge Web UI through Gluetun
```

This keeps the interfaces off the LAN by default. If remote administration is needed, prefer Tailscale or a private reverse proxy rather than publishing these ports.

## Data layout

All media services mount the repository root as `/data` so they share paths consistently:

```text
/data/downloads
/data/movies
/data/tv
/data/media
```

Application state lives in `docker/` and should be backed up separately from the media library.

## Observability

The observability stack is separated in `docker-compose.observability.yml`. It runs Grafana, Prometheus, Loki, Alloy, cAdvisor and integrates with Windows Exporter on the host.

These services bind to `127.0.0.1` by default and should stay private.

# Tailscale Grants example

This document shows a least-privilege access model for sharing Jellyfin while keeping the administration stack private.

## Desired policy

```text
Admin user      → all services
Jellyfin users  → Jellyfin only, tcp:8096
Guests          → no Sonarr, Radarr, Prowlarr, Bazarr, Deluge, Samba or observability
```

## Tag the media server

In the Tailscale admin console, tag the machine as:

```text
tag:media-server
```

The container hostname is:

```text
media-server-share
```

## Example Grants policy

Replace the email addresses with real Tailscale identities:

```json
{
  "groups": {
    "group:admin": [
      "your-email@gmail.com"
    ],
    "group:jellyfin-users": [
      "friend1@gmail.com",
      "friend2@gmail.com"
    ]
  },
  "tagOwners": {
    "tag:media-server": ["group:admin"]
  },
  "grants": [
    {
      "src": ["group:admin"],
      "dst": ["tag:media-server"],
      "ip": ["*"]
    },
    {
      "src": ["group:jellyfin-users"],
      "dst": ["tag:media-server"],
      "ip": ["tcp:8096"]
    }
  ]
}
```

## What this blocks

Jellyfin users can reach:

```text
media-server-share:8096
```

They should not be able to reach:

```text
media-server-share:5055  Jellyseerr
media-server-share:6767  Bazarr
media-server-share:8989  Sonarr
media-server-share:7878  Radarr
media-server-share:9696  Prowlarr
media-server-share:8112  Deluge Web UI
media-server-share:58846 Deluge daemon
media-server-share:3000  Grafana
media-server-share:9090  Prometheus
```

## Jellyfin users still need Jellyfin accounts

Tailscale controls network access. Jellyfin controls application access.

For each person:

1. Add them to Tailscale or share the node through Tailscale.
2. Create an individual Jellyfin user.
3. Disable server administration permissions for that Jellyfin user.
4. Apply library access restrictions if needed.

## Test the policy

From a non-admin invited device:

```text
http://media-server-share:8096      should work
http://media-server-share:8989      should fail
http://media-server-share:7878      should fail
http://media-server-share:8112      should fail
```

From the admin device, all required private services should remain reachable.

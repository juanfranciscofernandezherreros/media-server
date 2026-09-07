# Deluge through NordVPN with Gluetun

Deluge is routed through NordVPN by sharing Gluetun's network namespace. This keeps torrent traffic isolated from the rest of the media stack.

## Components

```text
Deluge → Gluetun → NordVPN/OpenVPN → Internet
```

- **NordVPN** is the VPN provider.
- **Gluetun** is the Docker VPN client and firewall container.
- **Deluge** is the download client using Gluetun's network.

Gluetun is not a second VPN provider. It is the container that connects Deluge to NordVPN.

## Credentials

Create `.env` from `.env.example`:

```powershell
Copy-Item .env.example .env
notepad .env
```

Set:

```env
NORDVPN_USER=your_manual_service_username
NORDVPN_PASSWORD=your_manual_service_password
```

Use NordVPN manual service credentials for OpenVPN. Do not use your normal Nord Account email and password.

## Compose model

Gluetun publishes only the Deluge Web UI locally:

```yaml
ports:
  - "127.0.0.1:8112:8112"
```

Deluge shares Gluetun's network:

```yaml
network_mode: "service:gluetun"
```

Because of this, Deluge should not publish its own ports.

## Sonarr and Radarr integration

Configure Deluge in Sonarr and Radarr as:

```text
Host: gluetun
Port: 8112
Password: Deluge Web UI password
Category: sonarr or radarr
```

Use separate categories:

```text
sonarr
radarr
```

This keeps completed downloads easier to track and import.

## Verification

Check Gluetun logs:

```powershell
docker compose logs --tail=100 gluetun
```

Expected signs:

```text
Initialization Sequence Completed
Public IP address is ...
```

Check the VPN IP from Gluetun:

```powershell
docker exec gluetun wget -qO- https://ipinfo.io/ip
```

Compare with the host IP:

```powershell
curl.exe https://ipinfo.io/ip
```

The Gluetun IP should be different from the host IP.

Check container exposure:

```powershell
docker compose ps
```

Expected result:

```text
gluetun  ... 127.0.0.1:8112->8112/tcp
deluge   ... no published ports
```

## Kill switch expectation

If Gluetun is stopped or the VPN tunnel is unhealthy, Deluge should not continue with a direct non-VPN route. This is the main reason Deluge is attached to Gluetun instead of installing NordVPN on the whole host.

## Performance notes

A VPN usually improves privacy, not speed. Download speed depends on:

- the selected NordVPN server,
- seeders and peers,
- Deluge connection limits,
- disk speed,
- network stability,
- tracker/indexer quality.

The current Compose file uses OpenVPN over UDP and Spain as the default region. If performance is poor, test another nearby country and compare sustained throughput.

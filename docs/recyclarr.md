# Recyclarr

Recyclarr centralizes Radarr and Sonarr configuration using YAML files. It is useful for keeping quality profiles, Custom Formats and scores consistent without editing every setting manually in the web UI.

In this stack, Recyclarr is optional and private by default:

```text
Recyclarr → Radarr  http://radarr:7878
Recyclarr → Sonarr  http://sonarr:8989
```

It does not replace Radarr or Sonarr. It only pushes configuration to them.

## Compose service

`docker-compose.yml` includes:

```yaml
recyclarr:
  image: ghcr.io/recyclarr/recyclarr:8
  container_name: recyclarr
  user: "1000:1000"
  environment:
    - TZ=Europe/Madrid
  volumes:
    - ./docker/recyclarr:/config
  restart: unless-stopped
  networks:
    - media-network
  depends_on:
    - sonarr
    - radarr
```

There are no published ports because Recyclarr is a CLI/sync tool, not a web panel.

## Prepare the configuration

Create the configuration directory:

```powershell
New-Item -ItemType Directory -Force .\docker\recyclarr
```

Copy the example file:

```powershell
Copy-Item .\docs\examples\recyclarr.yml .\docker\recyclarr\recyclarr.yml
notepad .\docker\recyclarr\recyclarr.yml
```

Replace:

```text
REPLACE_WITH_RADARR_API_KEY
REPLACE_WITH_SONARR_API_KEY
```

You can find each API key in:

```text
Radarr → Settings → General → Security → API Key
Sonarr → Settings → General → Security → API Key
```

Do not commit `docker/recyclarr/recyclarr.yml`; it contains secrets and the `docker/` directory is ignored by Git.

## First run

Start Radarr and Sonarr first:

```powershell
docker compose up -d radarr sonarr
```

Check that Recyclarr can run:

```powershell
docker compose run --rm recyclarr --version
```

List available configuration commands:

```powershell
docker compose run --rm recyclarr config --help
```

Sync all configured instances:

```powershell
docker compose run --rm recyclarr sync
```

Or sync only one side:

```powershell
docker compose run --rm recyclarr sync radarr
docker compose run --rm recyclarr sync sonarr
```

## Recommended Spanish profile strategy

Start simple and conservative. Do not force Spanish-only immediately, because strict rules can prevent Radarr/Sonarr from finding releases.

Recommended first strategy:

```text
Spanish / Castellano  positive score
Dual audio            small positive score
Latino                negative score if you do not want LATAM audio
English               negative score
Minimum score         0 at the beginning
Upgrade until score   Spanish target score
```

After you confirm your indexers find enough Spanish/Castellano releases, make the profile stricter.

## Safe workflow

Before applying large Recyclarr changes:

1. Back up Radarr and Sonarr configuration from `docker/radarr/` and `docker/sonarr/`.
2. Apply changes to one service first.
3. Check the Quality Profiles and Custom Formats in the web UI.
4. Only then apply the same approach to the other service.

Recommended order:

```powershell
docker compose run --rm recyclarr sync radarr
# inspect Radarr in the browser

docker compose run --rm recyclarr sync sonarr
# inspect Sonarr in the browser
```

## Notes

- Recyclarr should stay private; it does not need a web port.
- Keep API keys only in `docker/recyclarr/recyclarr.yml`.
- Use `gluetun:8112` only for the Radarr/Sonarr download client configuration. Recyclarr talks directly to `radarr:7878` and `sonarr:8989` inside Docker.
- Recyclarr does not download content, connect to indexers or replace Prowlarr.

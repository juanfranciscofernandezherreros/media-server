# Media Server con Jellyfin

Servidor multimedia doméstico desplegado con Docker Compose. El proyecto permite solicitar películas y series, localizar publicaciones, descargar contenido, organizarlo en bibliotecas, obtener subtítulos y reproducirlo desde Jellyfin.

El diseño actual prioriza privacidad y aprendizaje:

- **Jellyfin** se publica a través de Tailscale para que los usuarios autorizados puedan reproducir contenido sin abrir puertos en el router.
- **Deluge** sale a Internet a través de NordVPN usando Gluetun.
- **Sonarr** y **Radarr** se conectan a Deluge mediante la Web UI interna expuesta por Gluetun.
- **Paneles administrativos** quedan ligados a `127.0.0.1` para evitar exposición accidental en LAN o Internet.
- **Observabilidad** se despliega en un stack separado y también queda local por defecto.

> Este repositorio no incluye contenido multimedia. Utiliza únicamente fuentes y contenido cuya descarga y uso estén permitidos en tu jurisdicción.

## Instalación rápida en Windows

La forma más sencilla de arrancar el proyecto es usar el asistente de instalación:

```powershell
git clone https://github.com/juanfranciscofernandezherreros/media-server.git
cd media-server
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

El script realiza estas tareas:

- comprueba que Docker y Docker Compose están disponibles;
- crea las carpetas necesarias para configuración, descargas y bibliotecas;
- copia `.env.example` a `.env` si todavía no existe;
- avisa si faltan las credenciales manuales de NordVPN;
- valida `docker-compose.yml`;
- puede arrancar el stack con `docker compose up -d`;
- muestra los accesos locales principales;
- recuerda la configuración correcta de Sonarr/Radarr hacia Deluge;
- puede ejecutar `scripts/check-stack.ps1` al final.

Después de ejecutarlo, edita `.env` si todavía contiene los valores de ejemplo:

```env
NORDVPN_USER=tu_usuario_manual_de_nordvpn
NORDVPN_PASSWORD=tu_password_manual_de_nordvpn
```

Usa las credenciales manuales de servicio de NordVPN para OpenVPN, no tu email ni la contraseña normal de Nord Account.

## Arquitectura

```text
Usuarios autorizados
        │
        ▼
   Tailscale
        │
        ▼
 Jellyfin :8096
        │
        ▼
 movies/ y tv/

Jellyseerr ──> Sonarr ──┐
              Radarr ───┼──> Prowlarr
                         │
                         ▼
                  gluetun :8112
                         │
                         ▼
                  Deluge Web UI
                         │
                         ▼
                  NordVPN / OpenVPN
                         │
                         ▼
                      Internet

Deluge ──> downloads/ ──> Radarr/Sonarr importan ──> movies/ / tv/ ──> Jellyfin
                                  │
                                  └──> Bazarr subtítulos
```

La regla principal es sencilla:

```text
Acceso remoto privado  → Tailscale
Tráfico de descargas   → Gluetun + NordVPN
Administración web     → localhost
Router                 → 0 puertos abiertos
```

## Servicios

| Servicio | Función | Acceso recomendado |
| --- | --- | --- |
| Jellyfin | Reproducción multimedia | Tailscale, puerto `8096` |
| Tailscale | Red privada cifrada para acceso remoto | Nodo `media-server-share` |
| Gluetun | Cliente VPN para NordVPN y firewall de Deluge | Interno |
| Deluge | Cliente de descargas | `http://localhost:8112` y `gluetun:8112` desde Docker |
| Jellyseerr | Solicitudes de películas y series | `http://localhost:5055` |
| Sonarr | Gestión automática de series | `http://localhost:8989` |
| Radarr | Gestión automática de películas | `http://localhost:7878` |
| Prowlarr | Gestión de indexadores | `http://localhost:9696` |
| Bazarr | Gestión de subtítulos | `http://localhost:6767` |
| Samba | Acceso de solo lectura a archivos | Tailscale/SMB |
| Grafana | Observabilidad | `http://localhost:3000` |
| Prometheus | Métricas | `http://localhost:9090` |
| Loki | Logs | `http://localhost:3100` |

Plex no forma parte de este proyecto. Jellyfin es el único servidor de reproducción multimedia.

## Requisitos

- Docker Desktop o Docker Engine con Docker Compose.
- Cuenta de Tailscale para acceso remoto privado.
- Cuenta de NordVPN si quieres enrutar Deluge por VPN.
- Credenciales manuales de NordVPN para OpenVPN, no el email/contraseña normal de la cuenta.
- Espacio suficiente para `downloads/`, `movies/`, `tv/` y `docker/`.
- En Linux, un usuario con UID/GID `1000`, o adaptar `PUID` y `PGID`.

## Estructura de directorios

```text
media-server/
├── docker-compose.yml
├── docker-compose.observability.yml
├── .env.example
├── docker/              # Configuración persistente de contenedores
│   ├── jellyfin/
│   ├── jellyfin-cache/
│   ├── gluetun/
│   ├── deluge/
│   ├── sonarr/
│   ├── radarr/
│   ├── prowlarr/
│   ├── bazarr/
│   ├── jellyseerr/
│   └── tailscale/
├── downloads/           # Descargas de Deluge
├── movies/              # Biblioteca de películas
├── tv/                  # Biblioteca de series
├── media/               # Espacio adicional opcional
├── observability/       # Prometheus, Loki, Alloy y Grafana
├── scripts/             # Instalación y diagnóstico
└── docs/                # Documentación operativa
```

Las carpetas con configuración, bases de datos, credenciales, descargas y contenido multimedia deben permanecer fuera de Git.

## Configuración manual

Si prefieres no usar `scripts/install.ps1`, copia el archivo de ejemplo:

```powershell
Copy-Item .env.example .env
notepad .env
```

Configura al menos:

```env
GRAFANA_ADMIN_PASSWORD=change-this-password
NORDVPN_USER=tu_usuario_manual_de_nordvpn
NORDVPN_PASSWORD=tu_password_manual_de_nordvpn
```

Las variables `NORDVPN_USER` y `NORDVPN_PASSWORD` son las credenciales manuales de servicio de NordVPN para OpenVPN. No pegues tu contraseña normal de Nord Account.

Crea las carpetas de datos si no existen:

```powershell
New-Item -ItemType Directory -Force docker, downloads, movies, tv, media
```

## Puesta en marcha manual

```bash
git clone https://github.com/juanfranciscofernandezherreros/media-server.git
cd media-server
docker compose up -d
```

Comprueba el estado:

```bash
docker compose ps
```

El resultado esperado es que los servicios principales acaben en `healthy` o `running`.

Para detener el stack sin borrar datos:

```bash
docker compose down
```

No uses `docker compose down -v` salvo que quieras eliminar datos persistentes.

## Diagnóstico rápido

Después de instalar o cambiar la configuración, ejecuta:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-stack.ps1
```

Este script comprueba Docker, Compose, contenedores, Gluetun/NordVPN, conectividad interna, Jellyfin por Tailscale y puertos publicados peligrosos.

## Configurar Tailscale

Tras el primer arranque, revisa los logs:

```bash
docker compose logs tailscale
```

Abre la URL de autenticación que aparece en los logs y vincula el nodo a tu cuenta. El contenedor usa el hostname:

```text
media-server-share
```

Comprueba el estado:

```bash
docker exec tailscale tailscale status
```

Jellyfin comparte la red del contenedor `tailscale`, por lo que queda accesible a través del puerto `8096` publicado por ese contenedor.

Desde un dispositivo autorizado en Tailscale:

```text
http://media-server-share:8096
```

O usando la IP Tailscale del servidor:

```text
http://100.x.x.x:8096
```

Para máxima privacidad, no abras `8096` en el router.

## Configurar NordVPN con Gluetun

Gluetun actúa como cliente VPN dentro de Docker. NordVPN es el proveedor; Gluetun solo conecta el contenedor a NordVPN y aplica firewall/kill switch.

Comprueba que Gluetun conecta:

```powershell
docker compose logs --tail=100 gluetun
```

Busca líneas similares a:

```text
Initialization Sequence Completed
Public IP address is ...
```

Comprueba la IP de salida de Gluetun:

```powershell
docker exec gluetun wget -qO- https://ipinfo.io/ip
```

Compárala con la IP del host:

```powershell
curl.exe https://ipinfo.io/ip
```

Deben ser diferentes si Deluge está saliendo por la VPN.

## Configurar Deluge en Sonarr y Radarr

Deluge usa:

```yaml
network_mode: "service:gluetun"
```

Eso significa que Sonarr y Radarr no deben conectarse a `deluge` directamente. Deben conectarse a la Web UI/API de Deluge a través de Gluetun:

```text
Host: gluetun
Port: 8112
```

En Sonarr:

```text
Settings → Download Clients → Deluge
Host: gluetun
Port: 8112
Password: contraseña web de Deluge
Category: sonarr
Test → Save
```

En Radarr:

```text
Settings → Download Clients → Deluge
Host: gluetun
Port: 8112
Password: contraseña web de Deluge
Category: radarr
Test → Save
```

No uses `58846` para Sonarr/Radarr. Ese puerto corresponde al daemon/thin client de Deluge, no al flujo normal de integración usado aquí.

## Orden recomendado de configuración

### 1. Deluge

Abre:

```text
http://localhost:8112
```

Configura `/data/downloads` como carpeta de descarga.

### 2. Prowlarr

Abre:

```text
http://localhost:9696
```

Añade indexadores permitidos en tu ubicación y conecta Radarr/Sonarr desde **Settings → Apps**.

Direcciones internas:

```text
Radarr: http://radarr:7878
Sonarr: http://sonarr:8989
```

### 3. Radarr

Abre:

```text
http://localhost:7878
```

Configuración recomendada:

- Carpeta raíz: `/data/movies`
- Cliente de descarga: Deluge en `gluetun:8112`
- Categoría: `radarr`
- Perfil recomendado: `HD-1080p`
- Calidades permitidas: HDTV-1080p, WEB 1080p y Blu-ray 1080p
- Calidades excluidas: 720p, 2160p/4K y Remux 1080p

### 4. Sonarr

Abre:

```text
http://localhost:8989
```

Configuración recomendada:

- Carpeta raíz: `/data/tv`
- Cliente de descarga: Deluge en `gluetun:8112`
- Categoría: `sonarr`
- Perfil de calidad deseado para tus series

### 5. Bazarr

Abre:

```text
http://localhost:6767
```

Conecta Radarr y Sonarr usando:

```text
http://radarr:7878
http://sonarr:8989
```

### 6. Jellyfin

Abre desde el host:

```text
http://localhost:8096
```

O desde Tailscale:

```text
http://media-server-share:8096
```

Crea el administrador y añade bibliotecas:

```text
Películas: /data/movies
Series:    /data/tv
```

Para usuarios invitados, crea cuentas separadas y desactiva permisos de administración.

### 7. Jellyseerr

Abre:

```text
http://localhost:5055
```

Conecta Jellyfin usando:

```text
http://tailscale:8096
```

Conecta Radarr y Sonarr usando:

```text
http://radarr:7878
http://sonarr:8989
```

## Acceso remoto

No se recomienda abrir puertos en el router. El flujo recomendado es:

```text
Usuarios autorizados → Tailscale → Jellyfin
Tú → Tailscale → administración
Deluge → NordVPN → Internet
```

Para compartir Jellyfin con otras personas:

1. Invítalas a Tailscale.
2. Haz que instalen Tailscale en su dispositivo.
3. Crea un usuario individual en Jellyfin.
4. Dales la URL `http://media-server-share:8096` o la IP Tailscale.
5. Limita con Tailscale Grants/ACLs para que solo puedan llegar a `8096`.

Consulta `docs/tailscale-grants.md` para una política de ejemplo.

## Acceso a archivos con Samba

Samba comparte el proyecto en modo solo lectura:

```text
\\<IP_TAILSCALE>\Descargas
```

En macOS:

```text
smb://<IP_TAILSCALE>/Descargas
```

El volumen está montado como `:ro` para evitar borrados accidentales. No lo expongas fuera de Tailscale.

## Verificación rápida de seguridad

Después de cambios importantes:

```powershell
docker compose ps
docker exec gluetun wget -qO- https://ipinfo.io/ip
curl.exe https://ipinfo.io/ip
```

Comprueba que:

- `gluetun` está `healthy`.
- `deluge` está `healthy` y sin puertos propios publicados.
- `gluetun` solo publica `127.0.0.1:8112->8112/tcp`.
- Sonarr y Radarr hacen `Test` correcto contra `gluetun:8112`.
- El router no tiene port forwarding hacia `8096`, `8112`, `8989`, `7878`, `9696`, `6767`, `5055`, `58846` o `6881`.

Más detalles en `docs/operations.md`.

## Observabilidad en Windows

El archivo `docker-compose.observability.yml` despliega un stack separado con Grafana, Prometheus, Loki, Grafana Alloy y cAdvisor. Windows Exporter se ejecuta como servicio del sistema anfitrión y Prometheus accede a él mediante `host.docker.internal:9182`.

Instala Windows Exporter 0.31.7 desde una consola con permisos de administrador:

```powershell
curl.exe -L https://github.com/prometheus-community/windows_exporter/releases/download/v0.31.7/windows_exporter-0.31.7-amd64.msi -o windows_exporter.msi
msiexec.exe /i windows_exporter.msi /qn /norestart
```

Arranca observabilidad:

```bash
docker compose -f docker-compose.observability.yml up -d
```

| Servicio | Dirección |
| --- | --- |
| Grafana | `http://localhost:3000` |
| Prometheus | `http://localhost:9090` |
| Loki | `http://localhost:3100` |
| Alloy | `http://localhost:12345` |
| cAdvisor | `http://localhost:8080` |
| Windows Exporter | `http://localhost:9182/metrics` |

Consulta logs en Loki, métricas en Prometheus y dashboards en Grafana. Mantén estos servicios ligados a `127.0.0.1` salvo que los publiques explícitamente por Tailscale o un proxy privado.

## Comandos útiles

```bash
# Estado de servicios
docker compose ps

# Logs de Gluetun
docker compose logs -f gluetun

# Logs de Deluge
docker compose logs -f deluge

# Logs de Jellyfin
docker compose logs -f jellyfin

# Estado de Tailscale
docker exec tailscale tailscale status

# Validar Compose
docker compose config

# Reiniciar servicios principales
docker compose restart gluetun deluge sonarr radarr
```

## Documentación adicional

- `docs/architecture.md`: arquitectura y decisiones de diseño.
- `docs/deluge-vpn.md`: Gluetun, NordVPN y pruebas de salida.
- `docs/tailscale-grants.md`: ejemplo de permisos para admin e invitados.
- `docs/operations.md`: checklist operativo y troubleshooting.
- `SECURITY.md`: política de seguridad del proyecto.

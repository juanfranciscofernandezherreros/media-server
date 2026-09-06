# Media Server con Jellyfin

Servidor multimedia doméstico desplegado con Docker Compose. El sistema permite solicitar películas y series, localizar publicaciones, descargarlas, organizarlas, obtener subtítulos y reproducirlas desde Jellyfin.

## Arquitectura

```text
Jellyseerr
    ├── Radarr ──┐
    └── Sonarr ──┼── Prowlarr
                 └── Deluge ──> downloads ──> movies / tv ──> Jellyfin
                                      └──────────> Bazarr

Contenedores ──> cAdvisor ──> Prometheus ──> Grafana
       └───────> Alloy ─────> Loki ─────────> Grafana
Windows ───────> Windows Exporter ──────────> Prometheus
```

| Servicio | Función | Puerto |
| --- | --- | ---: |
| Jellyfin | Biblioteca y reproducción multimedia | 8096 |
| Jellyseerr | Solicitudes de películas y series | 5055 |
| Radarr | Gestión automática de películas | 7878 |
| Sonarr | Gestión automática de series | 8989 |
| Prowlarr | Gestión centralizada de indexadores | 9696 |
| Bazarr | Búsqueda y gestión de subtítulos | 6767 |
| Deluge | Cliente de descargas | 8112 |

Plex no forma parte de este proyecto. Jellyfin es el único servidor de reproducción multimedia.

## Requisitos

- Docker Desktop con Docker Compose.
- Espacio suficiente para descargas y bibliotecas.
- Los puertos indicados libres en el equipo anfitrión.
- En Linux, un usuario con UID y GID `1000`, o adaptar `PUID` y `PGID` en `docker-compose.yml`.

## Estructura de directorios

Al iniciar el proyecto, las aplicaciones crean sus configuraciones dentro de `docker/`. Los archivos multimedia se separan de las descargas:

```text
media-server/
├── docker-compose.yml
├── docker-compose.observability.yml
├── docker/       # Configuración persistente de los contenedores
├── observability/# Prometheus, Loki, Alloy y aprovisionamiento de Grafana
├── downloads/    # Descargas de Deluge
├── movies/       # Biblioteca de películas
├── tv/           # Biblioteca de series
└── media/        # Espacio adicional opcional
```

Las carpetas con configuraciones, bases de datos, credenciales, descargas y contenido multimedia están excluidas de Git.

## Puesta en marcha

Clona el repositorio y arranca los servicios:

```bash
git clone https://github.com/juanfranciscofernandezherreros/media-server.git
cd media-server
docker compose up -d
```

Comprueba su estado:

```bash
docker compose ps
```

Para detenerlos sin eliminar sus datos:

```bash
docker compose down
```

Las imágenes del stack multimedia están fijadas por digest SHA-256 y las de observabilidad por versión. Un `pull` no cambia silenciosamente los servicios multimedia: para actualizarlos hay que modificar deliberadamente sus digests.

Para descargar las imágenes configuradas y recrear el stack:

```bash
docker compose pull
docker compose up -d
```

## Orden de configuración

### 1. Deluge

Abre `http://localhost:8112` y configura `/data/downloads` como carpeta de descarga. Deluge será el cliente utilizado por Radarr y Sonarr.

### 2. Prowlarr

Abre `http://localhost:9696`, añade los indexadores permitidos en tu ubicación y conecta Radarr y Sonarr desde **Settings > Apps** utilizando sus claves API.

Direcciones internas entre contenedores:

- Radarr: `http://radarr:7878`
- Sonarr: `http://sonarr:8989`

### 3. Radarr

Abre `http://localhost:7878` y configura:

- Carpeta raíz: `/data/movies`
- Cliente de descarga: Deluge en `deluge:58846`
- Perfil recomendado: `HD-1080p`
- Calidades permitidas: HDTV-1080p, WEB 1080p y Blu-ray 1080p
- Calidades excluidas: 720p, 2160p/4K y Remux 1080p
- Actualizaciones de calidad hasta Blu-ray 1080p

El perfil limita las futuras selecciones. No convierte ni elimina automáticamente archivos existentes de otra resolución.

### 4. Sonarr

Abre `http://localhost:8989` y configura:

- Carpeta raíz: `/data/tv`
- Cliente de descarga: Deluge en `deluge:58846`
- El perfil de calidad que quieras aplicar a las series

### 5. Bazarr

Abre `http://localhost:6767`, conecta Radarr y Sonarr mediante sus direcciones internas y configura los idiomas y proveedores de subtítulos.

### 6. Jellyfin

Abre `http://localhost:8096`, crea el usuario administrador y añade estas bibliotecas:

- Películas: `/data/movies`
- Series: `/data/tv`

Si una descarga nueva no aparece inmediatamente, ejecuta **Panel de control > Bibliotecas > Escanear biblioteca**.

### 7. Jellyseerr

Abre `http://localhost:5055`, conecta Jellyfin y añade Radarr y Sonarr. Selecciona `HD-1080p` como perfil predeterminado de Radarr para que las solicitudes nuevas se descarguen en 1080p.

## Acceso desde la red local

Desde el propio servidor:

```text
http://localhost:8096
```

Desde un móvil, televisor u ordenador conectado a la misma red, sustituye `IP_DEL_SERVIDOR` por la IPv4 local del equipo:

```text
http://IP_DEL_SERVIDOR:8096
```

En Windows puedes obtenerla con `ipconfig`. No utilices direcciones de adaptadores virtuales ni una interfaz desconectada.

Para acceder desde Internet no se recomienda exponer directamente el puerto 8096. Es preferible utilizar una red privada como Tailscale o un proxy inverso con HTTPS y autenticación adecuada.

## Operación habitual

1. Solicita una película o serie desde Jellyseerr.
2. Radarr o Sonarr reciben la solicitud.
3. Prowlarr proporciona resultados de los indexadores configurados.
4. Deluge realiza la descarga.
5. Radarr o Sonarr importan y renombran el archivo en `movies/` o `tv/`.
6. Bazarr busca subtítulos cuando corresponda.
7. Jellyfin detecta el archivo y lo incorpora a la biblioteca.

## Comandos útiles

```bash
# Estado de los servicios
docker compose ps

# Registros de Jellyfin
docker compose logs -f jellyfin

# Reiniciar un servicio
docker compose restart jellyfin

# Validar la configuración
docker compose config
```

## Seguridad y copias de seguridad

- No publiques el contenido de `docker/`: contiene claves API, bases de datos y configuración privada.
- No subas archivos multimedia o descargas al repositorio.
- Cambia las contraseñas predeterminadas de los servicios.
- Realiza copias de seguridad periódicas de `docker/` con los contenedores detenidos.
- Mantén Docker Desktop y las imágenes actualizados.
- Utiliza únicamente fuentes y contenidos cuya descarga esté permitida en tu jurisdicción.


## Observabilidad en Windows

El archivo `docker-compose.observability.yml` despliega un stack separado con Grafana, Prometheus, Loki, Grafana Alloy y cAdvisor. Windows Exporter se ejecuta como servicio del sistema anfitrión y Prometheus accede a él mediante `host.docker.internal:9182`.

- cAdvisor aporta CPU, memoria, red y actividad de los contenedores.
- Windows Exporter aporta CPU, memoria, discos, red y servicios del anfitrión.
- Prometheus conserva las métricas durante 30 días.
- Alloy descubre los contenedores mediante el socket Docker y envía sus logs a Loki.
- Loki conserva los logs durante 30 días.
- Grafana incluye las fuentes de datos y el dashboard aprovisionados automáticamente.

Instala Windows Exporter 0.31.7 desde una consola con permisos de administrador:

```powershell
curl.exe -L https://github.com/prometheus-community/windows_exporter/releases/download/v0.31.7/windows_exporter-0.31.7-amd64.msi -o windows_exporter.msi
msiexec.exe /i windows_exporter.msi /qn /norestart
```

Arranca el stack de observabilidad:

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

Grafana se inicia con el usuario `admin` y la contraseña `admin`, y solicita cambiarla en el primer acceso. El dashboard **Media Server - Windows y Docker** queda aprovisionado automáticamente con métricas del host, consumo por contenedor y logs centralizados.

Para consultar únicamente los logs de Jellyseerr en **Explore > Loki**:

```logql
{container="jellyseerr"}
```

Para mostrar solo advertencias y errores:

```logql
{container="jellyseerr"} |~ "(?i)warn|error|exception|fatal|failed"
```

Comprueba los dos stacks y Windows Exporter:

```powershell
docker compose ps
docker compose -f docker-compose.observability.yml ps
Get-Service windows_exporter
```

Reinicia toda la plataforma:

```powershell
docker compose restart
docker compose -f docker-compose.observability.yml restart
Restart-Service windows_exporter
```

Para detener solamente la observabilidad sin afectar al servidor multimedia:

```bash
docker compose -f docker-compose.observability.yml down
```
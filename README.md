Markdown# Media Server con Jellyfin

Servidor multimedia doméstico desplegado con Docker Compose. El sistema permite solicitar películas y series, localizar publicaciones, descargarlas, organizarlas, obtener subtítulos y reproducirlas desde Jellyfin tanto en red local como de forma remota y segura mediante Tailscale y Samba.

## Arquitectura

```text
Jellyseerr
    ├── Radarr ──┐
    └── Sonarr ──┼── Prowlarr
                 └── Deluge ──> downloads ──> movies / tv ──> Jellyfin ──┐
                                       └──────────> Bazarr               │
                                                                         ▼
                                      Tailscale (Sidecar VPN) ◄── Samba (:ro)
                                                 │
                                                 ▼ (HTTPS / SMB)
                                         Clientes remotos

Contenedores ──> cAdvisor ──> Prometheus ──> Grafana
       └───────> Alloy ─────> Loki ─────────> Grafana
Windows ───────> Windows Exporter ──────────> Prometheus
ServicioFunciónModo de red / PuertoJellyfinBiblioteca y reproducción multimediaservice:tailscale (8096)TailscaleTúnel VPN cifrado y proxy seguro (Serve)Hostname: media-server-shareSambaAcceso a archivos en red (solo lectura)service:tailscale (SMB 445)JellyseerrSolicitudes de películas y series5055RadarrGestión automática de películas7878SonarrGestión automática de series8989ProwlarrGestión centralizada de indexadores9696BazarrBúsqueda y gestión de subtítulos6767DelugeCliente de descargas8112Plex no forma parte de este proyecto. Jellyfin es el único servidor de reproducción multimedia.RequisitosDocker Desktop con Docker Compose.Espacio suficiente para descargas y bibliotecas.Los puertos indicados libres en el equipo anfitrión.En Linux, un usuario con UID y GID 1000, o adaptar PUID y PGID en docker-compose.yml.Cuenta gratuita en Tailscale para acceso remoto seguro.Estructura de directoriosAl iniciar el proyecto, las aplicaciones crean sus configuraciones dentro de docker/. Los archivos multimedia se separan de las descargas:Plaintextmedia-server/
├── docker-compose.yml
├── docker-compose.observability.yml
├── docker/       # Configuración persistente (jellyfin, tailscale, sonarr, etc.)
├── observability/# Prometheus, Loki, Alloy y aprovisionamiento de Grafana
├── downloads/    # Descargas de Deluge
├── movies/       # Biblioteca de películas
├── tv/           # Biblioteca de series
└── media/        # Espacio adicional opcional
Las carpetas con configuraciones, bases de datos, credenciales, descargas y contenido multimedia están excluidas de Git.Puesta en marchaClona el repositorio y arranca los servicios:Bashgit clone [https://github.com/juanfranciscofernandezherreros/media-server.git](https://github.com/juanfranciscofernandezherreros/media-server.git)
cd media-server
docker compose up -d
Comprueba su estado:Bashdocker compose ps
Para detenerlos sin eliminar sus datos:Bashdocker compose down
Las imágenes del stack multimedia están fijadas por digest SHA-256 y las de observabilidad por versión. Un pull no cambia silenciosamente los servicios multimedia: para actualizarlos hay que modificar deliberadamente sus digests.Orden de configuración1. Tailscale y autenticación de la máquinaTras levantar los contenedores por primera vez, autentica el nodo de Tailscale:Revisa los registros del contenedor:Bashdocker compose logs tailscale
Haz clic en la URL de autenticación (https://login.tailscale.com/a/...) para vincular el nodo a tu cuenta de Tailscale.El nodo aparecerá registrado con el nombre media-server-share.2. Exponer Jellyfin mediante Tailscale Serve (HTTPS)Jellyfin corre bajo la red de Tailscale (service:tailscale). Para exponerlo con cifrado SSL/HTTPS automático dentro de la Tailnet:Bashdocker exec tailscale tailscale serve --bg 8096
Verifica el estado del proxy:Bashdocker exec tailscale tailscale serve status
Obtendrás un dominio seguro como https://media-server-share.<tailnet-id>.ts.net listo para usar en navegadores y aplicaciones móviles.3. DelugeAbre http://localhost:8112 y configura /data/downloads como carpeta de descarga. Deluge será el cliente utilizado por Radarr y Sonarr.4. ProwlarrAbre http://localhost:9696, añade los indexadores permitidos en tu ubicación y conecta Radarr y Sonarr desde Settings > Apps utilizando sus claves API.Direcciones internas entre contenedores:Radarr: http://radarr:7878Sonarr: http://sonarr:89895. RadarrAbre http://localhost:7878 y configura:Carpeta raíz: /data/moviesCliente de descarga: Deluge en deluge:58846Perfil recomendado: HD-1080pCalidades permitidas: HDTV-1080p, WEB 1080p y Blu-ray 1080pCalidades excluidas: 720p, 2160p/4K y Remux 1080p6. SonarrAbre http://localhost:8989 y configura:Carpeta raíz: /data/tvCliente de descarga: Deluge en deluge:58846El perfil de calidad deseado para las series7. BazarrAbre http://localhost:6767, conecta Radarr y Sonarr mediante sus direcciones internas y configura los idiomas y proveedores de subtítulos.8. JellyfinAbre http://localhost:8096, crea el usuario administrador y añade las bibliotecas:Películas: /data/moviesSeries: /data/tvPara crear usuarios destinados a invitados o amigos:Ve a Panel de control > Usuarios.Añade un nuevo usuario y desmarca Permitir a este usuario administrar este servidor.9. JellyseerrAbre http://localhost:5055 y configura la conexión con Jellyfin:Como Jellyfin comparte la red de Tailscale, conéctalo usando como host interno: http://tailscale:8096Vincula Radarr y Sonarr mediante sus nombres de servicio (http://radarr:7878 y http://sonarr:8989).Acceso remoto y compartidoNo es necesario abrir puertos en el router. El acceso se gestiona íntegramente a través de Tailscale y Samba.Compartir el servidor con otros usuariosAccede a la consola de administración de Tailscale.Localiza la máquina media-server-share.Haz clic en el menú contextual (...) y selecciona Share....Genera un enlace de invitación o envíalo al correo del usuario.El invitado debe aceptar la invitación e iniciar sesión en la aplicación de Tailscale en su equipo o teléfono.Conexión a Jellyfin (Streaming)Con Tailscale conectado en el dispositivo cliente, abre la app de Jellyfin o el navegador:Plaintexthttps://media-server-share.<tailnet-id>.ts.net
(También accesible mediante http://<IP_TAILSCALE>:8096).Conexión a Samba (Descarga directa de archivos)El contenedor samba expone la raíz del proyecto en modo de solo lectura (:ro) para evitar borrados accidentales:Windows: En el Explorador de archivos, introduce:Plaintext\\<IP_TAILSCALE>\Descargas
macOS: En Finder, pulsa Cmd + K e introduce:Plaintextsmb://<IP_TAILSCALE>/Descargas
Android: Usa aplicaciones como Cx Explorador de Archivos o VLC, añadiendo un servidor SMB con la IP de Tailscale y acceso anónimo/invitado.Operación habitualSolicita una película o serie desde Jellyseerr.Radarr o Sonarr reciben la solicitud.Prowlarr proporciona resultados de los indexadores configurados.Deluge realiza la descarga.Radarr o Sonarr importan y renombran el archivo en movies/ o tv/.Bazarr busca subtítulos cuando corresponda.Jellyfin detecta el archivo y lo incorpora a la biblioteca.Comandos útilesBash# Estado de los servicios
docker compose ps

# Comprobar el estado del túnel Tailscale y dispositivos conectados
docker exec tailscale tailscale status

# Registros de Jellyfin
docker compose logs -f jellyfin

# Reiniciar el stack completo
docker compose restart
Observabilidad en WindowsEl archivo docker-compose.observability.yml despliega un stack separado con Grafana, Prometheus, Loki, Grafana Alloy y cAdvisor. Windows Exporter se ejecuta como servicio del sistema anfitrión y Prometheus accede a él mediante host.docker.internal:9182.Instala Windows Exporter 0.31.7 desde una consola con permisos de administrador:PowerShellcurl.exe -L [https://github.com/prometheus-community/windows_exporter/releases/download/v0.31.7/windows_exporter-0.31.7-amd64.msi](https://github.com/prometheus-community/windows_exporter/releases/download/v0.31.7/windows_exporter-0.31.7-amd64.msi) -o windows_exporter.msi
msiexec.exe /i windows_exporter.msi /qn /norestart
Crea la configuración local de credenciales:PowerShellCopy-Item .env.example .env
notepad .env
Arranca el stack de observabilidad:Bashdocker compose -f docker-compose.observability.yml up -d
ServicioDirecciónGrafanahttp://localhost:3000Prometheushttp://localhost:9090Lokihttp://localhost:3100Alloyhttp://localhost:12345cAdvisorhttp://localhost:8080Windows Exporterhttp://localhost:9182/metrics
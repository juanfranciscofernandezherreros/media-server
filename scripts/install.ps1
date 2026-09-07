# Guided Windows installer for Media Server
# Run from the repository root:
#   powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1

$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Gray
}

function Assert-Command {
    param(
        [string]$Name,
        [string]$Help
    )

    $Command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $Command) {
        throw "$Name is not available. $Help"
    }
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Ok "Created $Path"
    }
    else {
        Write-Info "$Path already exists"
    }
}

Write-Host ""
Write-Host "Media Server guided install" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script prepares the local folders, creates .env when needed, validates Docker Compose, starts the stack and prints the next manual steps."

Write-Section "Repository root"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot
Write-Ok "Using repository root: $RepoRoot"

Write-Section "Prerequisites"

try {
    Assert-Command "docker" "Install Docker Desktop and start it before running this script."
    docker version | Out-Null
    Write-Ok "Docker is available"
}
catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

try {
    docker compose version | Out-Null
    Write-Ok "Docker Compose is available"
}
catch {
    Write-Host "[FAIL] Docker Compose is not available through 'docker compose'. Update Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Section "Directory layout"

$Directories = @(
    "docker",
    "docker/jellyfin",
    "docker/jellyfin-cache",
    "docker/gluetun",
    "docker/deluge",
    "docker/sonarr",
    "docker/radarr",
    "docker/prowlarr",
    "docker/bazarr",
    "docker/jellyseerr",
    "docker/tailscale",
    "downloads",
    "movies",
    "tv",
    "media"
)

foreach ($Directory in $Directories) {
    Ensure-Directory $Directory
}

Write-Section "Environment file"

if (-not (Test-Path ".env")) {
    if (-not (Test-Path ".env.example")) {
        Write-Host "[FAIL] .env.example was not found" -ForegroundColor Red
        exit 1
    }

    Copy-Item ".env.example" ".env"
    Write-Ok "Created .env from .env.example"
    Write-Warn "Edit .env and set your NordVPN manual OpenVPN credentials before expecting Gluetun to connect."
}
else {
    Write-Info ".env already exists; leaving it unchanged"
}

$EnvContent = Get-Content ".env" -Raw
if ($EnvContent -match "tu_usuario_manual_de_nordvpn" -or $EnvContent -match "tu_password_manual_de_nordvpn") {
    Write-Warn "NordVPN placeholders are still present in .env"
    Write-Warn "Open .env and replace NORDVPN_USER / NORDVPN_PASSWORD with NordVPN manual service credentials."
}
else {
    Write-Ok ".env does not contain the default NordVPN placeholders"
}

Write-Section "Compose validation"

try {
    docker compose config --quiet
    Write-Ok "docker-compose.yml is valid"
}
catch {
    Write-Host "[FAIL] docker-compose.yml validation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Section "Start stack"

$Start = Read-Host "Start the media stack now with 'docker compose up -d'? [Y/n]"
if ($Start -eq "" -or $Start.ToLowerInvariant() -eq "y" -or $Start.ToLowerInvariant() -eq "yes" -or $Start.ToLowerInvariant() -eq "s" -or $Start.ToLowerInvariant() -eq "si" -or $Start.ToLowerInvariant() -eq "sí") {
    docker compose up -d
    Write-Ok "Stack start requested"
}
else {
    Write-Warn "Stack was not started. Run 'docker compose up -d' when ready."
}

Write-Section "Current status"

docker compose ps

Write-Section "Tailscale authentication"

Write-Host "If this is the first run, authenticate the Tailscale container:"
Write-Host ""
Write-Host "  docker compose logs tailscale"
Write-Host ""
Write-Host "Open the login URL shown in the logs, then use:"
Write-Host ""
Write-Host "  http://media-server-share:8096"
Write-Host ""
Write-Host "or the Tailscale IP of the server."

Write-Section "Next service setup"

Write-Host "Open these local admin panels from this machine:"
Write-Host ""
Write-Host "  Jellyfin:   http://localhost:8096"
Write-Host "  Deluge:     http://localhost:8112"
Write-Host "  Jellyseerr: http://localhost:5055"
Write-Host "  Sonarr:     http://localhost:8989"
Write-Host "  Radarr:     http://localhost:7878"
Write-Host "  Prowlarr:   http://localhost:9696"
Write-Host "  Bazarr:     http://localhost:6767"
Write-Host ""
Write-Host "Important Sonarr/Radarr download client settings:"
Write-Host ""
Write-Host "  Host: gluetun"
Write-Host "  Port: 8112"
Write-Host "  Category: sonarr / radarr"
Write-Host ""
Write-Host "Do not use deluge:58846 for Sonarr/Radarr in this deployment."

Write-Section "Diagnostics"

if (Test-Path ".\scripts\check-stack.ps1") {
    $RunDiagnostics = Read-Host "Run diagnostics now? [Y/n]"
    if ($RunDiagnostics -eq "" -or $RunDiagnostics.ToLowerInvariant() -eq "y" -or $RunDiagnostics.ToLowerInvariant() -eq "yes" -or $RunDiagnostics.ToLowerInvariant() -eq "s" -or $RunDiagnostics.ToLowerInvariant() -eq "si" -or $RunDiagnostics.ToLowerInvariant() -eq "sí") {
        powershell -ExecutionPolicy Bypass -File ".\scripts\check-stack.ps1"
    }
    else {
        Write-Info "Skipped diagnostics. You can run: powershell -ExecutionPolicy Bypass -File .\scripts\check-stack.ps1"
    }
}
else {
    Write-Warn "scripts/check-stack.ps1 was not found"
}

Write-Section "Done"
Write-Host "Installation helper completed." -ForegroundColor Green
Write-Host "Keep the router closed. Use Tailscale for remote access and Gluetun/NordVPN for Deluge traffic."

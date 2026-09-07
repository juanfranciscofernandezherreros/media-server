# Media Server diagnostic script for Windows / PowerShell
# Run from the repository root:
#   powershell -ExecutionPolicy Bypass -File .\scripts\check-stack.ps1

$ErrorActionPreference = "Stop"
$script:HasFailures = $false

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Yellow
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    $script:HasFailures = $true
}

function Invoke-CheckedCommand {
    param(
        [string]$Description,
        [scriptblock]$Command
    )

    try {
        & $Command
        Write-Ok $Description
    }
    catch {
        Write-Fail "$Description failed: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Media Server diagnostics" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

Write-Section "Docker availability"

try {
    docker version | Out-Null
    Write-Ok "Docker is available"
}
catch {
    Write-Fail "Docker is not available or Docker Desktop is not running"
    exit 1
}

Write-Section "Docker Compose configuration"
Invoke-CheckedCommand "docker-compose.yml is valid" { docker compose config --quiet }

Write-Section "Container status"

$ExpectedContainers = @(
    "tailscale",
    "jellyfin",
    "gluetun",
    "deluge",
    "sonarr",
    "radarr",
    "prowlarr",
    "bazarr",
    "jellyseerr"
)

foreach ($Container in $ExpectedContainers) {
    try {
        $Status = docker inspect -f "{{.State.Status}}" $Container 2>$null

        if (-not $Status) {
            Write-Fail "$Container does not exist"
            continue
        }

        if ($Status -ne "running") {
            Write-Fail "$Container is $Status"
            continue
        }

        $Health = docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}" $Container 2>$null

        if ($Health -eq "healthy" -or $Health -eq "none") {
            Write-Ok "$Container is running ($Health)"
        }
        elseif ($Health -eq "starting") {
            Write-Warn "$Container is running but health is starting"
        }
        else {
            Write-Fail "$Container is running but health is $Health"
        }
    }
    catch {
        Write-Fail "Could not inspect $Container: $($_.Exception.Message)"
    }
}

Write-Section "Gluetun / NordVPN public IP"

$VpnIp = $null
try {
    $VpnIp = (docker exec gluetun wget -qO- https://ipinfo.io/ip).Trim()
    if ($VpnIp) {
        Write-Ok "Gluetun public IP: $VpnIp"
    }
    else {
        Write-Fail "Could not get Gluetun public IP"
    }
}
catch {
    Write-Fail "Gluetun cannot reach ipinfo.io: $($_.Exception.Message)"
}

Write-Section "Host public IP"

try {
    $HostIp = (curl.exe -s https://ipinfo.io/ip).Trim()
    if ($HostIp) {
        Write-Ok "Host public IP: $HostIp"

        if ($VpnIp -and $HostIp -eq $VpnIp) {
            Write-Warn "Host IP and Gluetun IP are the same. Check whether the host is also using a VPN."
        }
        elseif ($VpnIp) {
            Write-Ok "Host IP and Gluetun IP are different"
        }
    }
    else {
        Write-Warn "Could not get host public IP"
    }
}
catch {
    Write-Warn "Could not get host public IP: $($_.Exception.Message)"
}

Write-Section "Internal service connectivity"

Invoke-CheckedCommand "Sonarr can reach Deluge Web UI through gluetun:8112" {
    docker exec sonarr curl -fsS http://gluetun:8112 | Out-Null
}

Invoke-CheckedCommand "Radarr can reach Deluge Web UI through gluetun:8112" {
    docker exec radarr curl -fsS http://gluetun:8112 | Out-Null
}

Invoke-CheckedCommand "Jellyfin responds through the Tailscale sidecar namespace" {
    docker exec tailscale wget -qO- http://127.0.0.1:8096 | Out-Null
}

Write-Section "Published port exposure"

try {
    $ComposePs = docker compose ps

    $DangerousPatterns = @(
        "0.0.0.0:5055",
        "0.0.0.0:6767",
        "0.0.0.0:7878",
        "0.0.0.0:8989",
        "0.0.0.0:9696",
        "0.0.0.0:8112",
        "0.0.0.0:58846",
        "0.0.0.0:6881",
        "[::]:5055",
        "[::]:6767",
        "[::]:7878",
        "[::]:8989",
        "[::]:9696",
        "[::]:8112",
        "[::]:58846",
        "[::]:6881"
    )

    foreach ($Pattern in $DangerousPatterns) {
        if ($ComposePs -match [regex]::Escape($Pattern)) {
            Write-Fail "Dangerous host bind detected: $Pattern"
        }
    }

    Write-Ok "No dangerous administrative host binds were detected"

    if ($ComposePs -match [regex]::Escape("0.0.0.0:8096") -or $ComposePs -match [regex]::Escape("[::]:8096")) {
        Write-Warn "Jellyfin is bound on the host through the Tailscale sidecar. Keep router port-forwarding disabled for port 8096."
    }
}
catch {
    Write-Fail "Could not inspect published ports: $($_.Exception.Message)"
}

Write-Section "Manual checks"
Write-Host "Confirm these settings in Sonarr and Radarr:"
Write-Host "  Download client: Deluge"
Write-Host "  Host: gluetun"
Write-Host "  Port: 8112"
Write-Host "  Category: sonarr / radarr"
Write-Host ""
Write-Host "Confirm your router does not forward these ports:"
Write-Host "  8096, 8112, 8989, 7878, 9696, 6767, 5055, 58846, 6881"

Write-Section "Result"

if ($HasFailures) {
    Write-Host "Diagnostics completed with failures." -ForegroundColor Red
    exit 1
}

Write-Host "Diagnostics completed successfully." -ForegroundColor Green
exit 0

# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Added

- Documentation for the private Tailscale media-server deployment.
- Documentation for routing Deluge through NordVPN using Gluetun.
- Tailscale Grants example for allowing invited users to access only Jellyfin.
- Operations checklist for validating Docker health, VPN routing, Tailscale access and router exposure.

### Changed

- Rewrote the README to match the current Compose architecture.
- Clarified that Sonarr and Radarr should connect to Deluge through `gluetun:8112`.
- Expanded `.env.example` with NordVPN/Gluetun guidance.
- Strengthened the security policy for private-only operation.

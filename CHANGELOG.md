# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [2.0.0] - 2026-09-09

### Changed

- Adopted canonical Gitflow with only `main` and `develop` as permanent branches.
- Added temporary versioned `feature/*`, `release/*`, and `hotfix/*` branch rules.
- Updated branch-policy automation and repository documentation for the new promotion paths.

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

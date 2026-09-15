# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [2.3.0] - 2026-09-15

### Changed

- Required every release and hotfix publication to update `CHANGELOG.md` before the final tag and GitHub Release are created.
- Required release entries to record the temporary branch, pull requests, confirmed merges, required checks, final tag, and GitHub Release publication.

### Release workflow

- Created `release/2.3.0` from clean, synchronized `develop`.
- Promotion will be reviewed and merged into `main`, then integrated back into `develop` without rebase after required checks pass.
- The final tag will be `v2.3.0` and the GitHub Release will be published from `main` after the promotion completes.
## [2.1.1] - 2026-09-15

### Fixed

- Required every feature branch to originate from a clean, synchronized `develop` branch.
- Corrected the documented Gitflow diagram and synchronization sequence.

## [2.1.0] - 2026-09-15

### Changed

- Configured the Tailscale container to use kernel TUN networking instead of userspace networking.
- Declared `/dev/net/tun` as a Docker device while retaining the required network capabilities.

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

# Changelog

Notable changes to this egg. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions are git tags.

## [Unreleased]

## [1.0.0]

First working version.

- All-in-one image: Postgres 16 + Redis + YAGPDB under supervisord, built from
  source in a multi-stage Dockerfile.
- State kept under `/home/container`; databases bound to loopback only.
- Dashboard binds to the Pterodactyl-assigned port; `-exthttps` for a TLS
  proxy in front.
- Pterodactyl egg (`egg-yagpdb.json`) with variables for bot token, client
  ID/secret, owner and host.
- GitHub Actions workflow that builds and pushes the image to GHCR on release.

# YAGPDB on Pterodactyl

Run [YAGPDB](https://github.com/botlabs-gg/yagpdb) — a self-hosted, general
purpose Discord bot — as a single Pterodactyl server. Postgres, Redis and the
bot all live in one container managed by supervisord, and every bit of state
sits under `/home/container` so it survives restarts and reinstalls.

Upstream expects a docker-compose stack: separate database, cache and bot
containers. Pterodactyl gives you one container per server, so this squeezes the
whole thing into that one container. It isn't the textbook way to run YAGPDB,
but it's the way that fits the panel, and it keeps everything to a single egg
you can hand to anyone.

## How it works

- Built from source in a multi-stage Dockerfile — YAGPDB ships no prebuilt
  binaries, so there's a Go build stage and a slim runtime stage.
- On first boot `entrypoint.sh` initialises the Postgres cluster, creates the
  `yagpdb` role and database, then hands off to supervisord, which keeps
  Postgres, Redis and the bot alive.
- Postgres and Redis bind to loopback only — never exposed through a Pterodactyl
  allocation.
- The dashboard listens on the server's assigned port. Discord OAuth needs HTTPS
  on a real domain, so the bot runs with `-exthttps` and expects a reverse proxy
  to terminate TLS in front of it.

## Requirements

- A registry to hold the image — GHCR works, and the workflow pushes there on
  every release.
- A domain and a TLS-terminating reverse proxy.
- A Discord application (bot token, client ID and secret).

## Releases

Versions are git tags. Tag a commit and push it; the
[workflow](.github/workflows/docker.yml) builds the image and pushes `:X.Y.Z`,
`:X.Y` and `:latest` to GHCR. Pushes to `main` publish a `:main` tag.

```sh
git tag v1.0.0
git push origin v1.0.0
```

See [CHANGELOG.md](CHANGELOG.md) for what changed between versions.

## Files

| File | What it is |
|------|-----------|
| `Dockerfile` | Two-stage build: compile YAGPDB, then assemble the runtime image |
| `entrypoint.sh` | First-boot DB setup, wiring, and handoff to supervisord |
| `supervisord.conf` | Keeps Postgres, Redis and the bot running |
| `egg-yagpdb.json` | The Pterodactyl egg you import |
| `.github/workflows/docker.yml` | Builds and pushes the image on release |

## License

[MIT](LICENSE). YAGPDB itself is also MIT-licensed.

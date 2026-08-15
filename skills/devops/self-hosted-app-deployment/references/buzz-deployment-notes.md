# Buzz deployment notes

Project: https://github.com/block/buzz
Repo path on server: `/data/runtime/hermes-rw/buzz`

## Architecture

- Rust workspace with relay crate `buzz-relay`.
- WebSocket relay on port 3000; health on 8080; metrics on 9102.
- Backing services: Postgres 17, Redis 7, MinIO/S3.
- Uses Hermit for pinned toolchain: `. ./bin/activate-hermit`.

## What worked

- Cloned existing repo at `/data/runtime/hermes-rw/buzz` (already present).
- Hermit auto-installed Rust 1.95, Node 24, pnpm 11, just 1.46.
- Release build succeeded:
  ```bash
  cd /data/runtime/hermes-rw/buzz
  . ./bin/activate-hermit
  cargo build --release -p buzz-relay --bin buzz-relay
  ```
- Binary produced: `target/release/buzz-relay` (~58 MB).

## Blocker

Docker socket restricted to `docker` group; `computer` user not in group. `sudo` is disabled (`no_new_privs`). Rootless Docker setup also blocked (`uidmap` package missing).

Error:
```
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

## Required admin action

```bash
sudo usermod -aG docker computer
```

Then re-login or `newgrp docker`.

## Prepared config

- `/data/runtime/hermes-rw/buzz/deploy/compose/.env` created from `.env.example` with dev values.
- Validation passed: `docker compose --env-file .env -f compose.yml -f compose.dev.yml config`.

## Access points after start

- Relay: `ws://localhost:3000` / `http://localhost:3000`
- Health: `http://localhost:3000/_liveness`
- Adminer DB UI: `http://localhost:8082`
- MinIO console: `http://localhost:9001`
- Prometheus: `http://localhost:9090`

## Next steps after Docker access is granted

```bash
cd /data/runtime/hermes-rw/buzz/deploy/compose
./run.sh pull
./run.sh start
```

Then verify with:
```bash
curl -fsS http://localhost:3000/_liveness
./run.sh status
```

## Source-build command (fallback)

If Docker remains blocked, the relay binary can run directly once Postgres/Redis/MinIO are provided:

```bash
cd /data/runtime/hermes-rw/buzz
. ./bin/activate-hermit
./target/release/buzz-relay
```

Default env expects `DATABASE_URL`, `REDIS_URL`, etc. from `.env` in project root.

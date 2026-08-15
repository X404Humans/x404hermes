---
name: self-hosted-app-deployment
description: "Deploy and run self-hosted open-source apps on a Linux server, including source builds, Docker Compose paths, and permission diagnostics."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [self-hosting, deployment, docker, linux, server]
    related_skills: [github-repo-management]
---

# Self-Hosted App Deployment

Install, build, and run open-source server applications on a Linux host where the agent may not have root/sudo access.

## When to use

- User asks to "install X on our server" for an open-source project that ships a Docker Compose or source-build path.
- The target environment is a shared/restricted server where `computer` lacks root or `docker` group membership.
- You need a repeatable fallback path when the container route is blocked.

## First: inspect the repo and its deployment docs

1. Clone or locate the repo.
2. Read `README.md`, `CONTRIBUTING.md`, and any `deploy/` / `docker-compose.yml` / `.env.example` files.
3. Identify the project's blessed local-dev and production deployment paths.
4. Check whether the repo uses a pinned toolchain (Hermit, rust-toolchain, etc.).

## Second: verify environment capabilities

Run a quick diagnostic before committing to a Docker-based path:

```bash
# Docker access
docker info 2>&1 | head -20
ls -la /var/run/docker.sock
id
getent group docker

# No-root fallbacks
command -v podman && podman --version
command -v nerdctl && nerdctl --version

# Toolchain
command -v cargo && cargo --version
command -v node && node --version
```

## Third: choose the path

| Situation | Path |
|-----------|------|
| In `docker` group or root/sudo available | Docker Compose from project's `deploy/` or root compose file |
| Docker socket restricted, no sudo, rootless not viable | Build from source + run backing services natively or via user-space tools |
| Podman/nerdctl available | Translate `docker compose` to the available engine |

## Docker Compose path

1. Copy `.env.example` → `.env` in the correct directory (usually project root or `deploy/compose/`).
2. Replace placeholder secrets with stable values.
3. For local/internal use, disable closed-relay/prod-only gates such as `BUZZ_REQUIRE_AUTH_TOKEN`, `BUZZ_REQUIRE_RELAY_MEMBERSHIP`, and point `RELAY_URL` / `BUZZ_MEDIA_BASE_URL` at the actual host/port.
4. Validate config: `docker compose --env-file .env -f compose.yml [-f compose.dev.yml] config`.
5. Start: `docker compose up -d --wait` or the project's wrapper script.

## Source-build fallback

When Docker is unavailable:

1. Activate the project's pinned toolchain (e.g., `. ./bin/activate-hermit`).
2. Build the release binary: `cargo build --release -p <crate> --bin <bin>` (or project-specific equivalent).
3. Check the binary's expected backing services from `.env.example` and run them by some other means (system packages, another host, etc.).
4. Run the binary directly and confirm it binds and serves traffic.

## Common blockers and diagnostics

### Docker: `permission denied while trying to connect to the docker API`

- Cause: user is not in the `docker` group and cannot use `sudo`.
- Fix (requires admin): `sudo usermod -aG docker $USER`, then re-login or `newgrp docker`.
- Workaround: build from source if the project supports it.

### Build: `Blocking waiting for file lock on artifact directory`

- Cause: another `cargo`/`rustc` process is holding the lock.
- Fix: identify and terminate the competing process, or wait for it to finish.

### Containerized environment with `no_new_privs`

- `sudo` and `su` are disabled.
- Use group membership changes from the host admin, not privilege escalation inside the container.

## How to report status

When a deployment is blocked, give the user:
1. What completed (cloned, built, config prepared).
2. The exact blocker and error text.
3. The specific action they or an admin must take.
4. The URLs/ports they will use once unblocked.

## References

- `references/buzz-deployment-notes.md` — notes from installing `block/buzz` on a restricted Linux server.

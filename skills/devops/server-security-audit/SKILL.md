---
name: server-security-audit
description: "Audit and harden Linux servers used by AI agents and their human operators, balancing security with legitimate agent workflows."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [security, hardening, linux, server, audit, ssh, firewall, cloudflare]
    related_skills: [self-hosted-app-deployment]
---

# Server Security Audit & Hardening

Audit a Linux server that runs agent-powered workloads (research, outbound APIs, autonomous businesses, data-context access, code deployment, self-updates) and propose a hardening plan that does not break legitimate agent workflows.

## When to use

- User asks for a "security audit" or "harden the server".
- You are inspecting a VPS that hosts Hermes, Ollama, Caddy/Traefik, Docker services, or a `/computer` cloud-computer setup.
- You need to reconcile tighter permissions with the need for agents and humans to deploy code, edit configs, and restart services.

## Golden rule: verify before you assume

The user may say the server is "behind Cloudflare" or "behind a tunnel". That statement is about the HTTP/HTTPS path only. You must independently verify:

- What services are listening on what interfaces (`ss -tulnp`).
- Whether the host has a public IP directly attached.
- Whether SSH or other admin ports are reachable from the internet.
- Whether a tunnel daemon (e.g., `cloudflared`) is actually running.

**Never recommend host-level firewall or SSH changes until you confirm the host boundary.** A Cloudflare-fronted website does not imply SSH is tunneled or protected.

## Workflow

### Phase 1: Read-only reconnaissance

Run these before proposing any change:

```bash
# Identity and platform
hostname; uname -a; cat /etc/os-release
id; whoami

# Users, groups, sudoers
getent passwd | grep -vE 'nologin|false'
getent group
sudo -l
cat /etc/sudoers 2>/dev/null
ls -la /etc/sudoers.d/
for f in /etc/sudoers.d/*; do echo "=== $f ==="; cat "$f"; done

# SSH
ss -tulnp | grep ':22 '
grep -RvhE '^#|^$' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf | sort -u

# Boundary verification
ss -tulnp
curl -s --max-time 5 https://api.ipify.org
dig +short <hostname> 2>/dev/null
curl -s --max-time 5 -I https://<hostname> 2>/dev/null | grep -iE 'cf-|server'
ps aux | grep -iE 'cloudflare|cloudflared|tunnel' | grep -v grep
which cloudflared 2>/dev/null

# Firewall
ufw status verbose 2>/dev/null
iptables -L -n 2>/dev/null | head -20

# Services and secrets
systemctl list-units --type=service --state=running --no-pager
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
find /home /data /root -maxdepth 4 \( -name '.env*' -o -name '*token*' -o -name '*secret*' -o -name '*.key' -o -name '*.pem' -o -name 'credentials*' \) 2>/dev/null
```

### Phase 2: Boundary triage

Use the results to classify each listening service:

| Service | Public IP? | Public DNS? | Via tunnel? | Risk |
|---|---|---|---|---|
| HTTP/HTTPS | yes/no | yes/no | yes/no | depends on tunnel/auth |
| SSH | yes/no | no | no | **HIGH** if yes |
| Caddy admin | no | no | no | low if localhost-only |
| Ollama/API ports | no | no | no | low if localhost-only |
| Docker socket | n/a | n/a | n/a | root-equivalent if misused |

### Phase 3: Report, don't change

1. Write findings to the team KB (e.g., `/data/knowledge/ops-guides/server-security-audit-YYYY-MM-DD.md`).
2. Summarize top risks in-chat.
3. Propose a phased hardening plan.
4. **Ask for explicit approval before changing sudoers, SSH, firewall, or secrets.**

### Phase 4: Harden only after approval

Typical safe changes (confirm with the human first):

- Remove `NOPASSWD: ALL` from agent accounts; route root actions through validated helper scripts or require a password.
- Explicitly set `PasswordAuthentication no`, `PermitRootLogin prohibit-password`, `X11Forwarding no`, `MaxAuthTries 3` in `sshd_config`.
- Remove stale cloud-init `PasswordAuthentication yes` snippets.
- Install fail2ban or equivalent for sshd.
- Enable UFW/nftables with default-deny inbound, allowing 80/443 and rate-limited SSH.
- Bind internal services (Ollama, app servers, Caddy admin API) to `127.0.0.1` only.
- Rotate secrets found in world-readable or old backup locations.
- Move old backups containing `.env`/`auth.json` to encrypted or off-host storage.
- Disable unprivileged user namespaces if not required.
- Ensure kernel security updates are installed and followed by a reboot.

## How to preserve legitimate agent workflows

| Workflow | Preservation strategy |
|---|---|
| Research / outbound APIs | Do not block egress; agents need network access |
| Outbound marketing / posting | Keep egress open; lock down secrets only |
| Autonomous businesses / code deploy | Use helper scripts or a dedicated deploy group, not `NOPASSWD: ALL` |
| Data context (KB, memory) | Group ownership + ACLs, no root required |
| Tooling / browser / terminal | `computer` account keeps normal tools |
| Server self-updates | Allow-listed sudo commands with logging |
| Caddy / Docker / service changes | Helper scripts with argument validation |

## Common false boundaries

- **"Behind Cloudflare"** → usually means HTTP/HTTPS is proxied. SSH, custom TCP ports, and UDP may still be directly exposed.
- **"No host firewall"** → may be intentional if the provider has a cloud firewall, but verify before relying on it.
- **"Password auth is disabled"** → check for `sshd_config.d/*.conf` snippets that re-enable it, and for password-locked vs password-set accounts.

## Red flags that override the "don't change" rule

If any of these are found, pause and alert the user immediately before proceeding, because they are active compromise risks:

- `NOPASSWD: ALL` on an interactive/agent account.
- World-readable SSH private keys or `.env` files.
- Running root shell from a remote agent session.
- Unauthorized `authorized_keys` entries.
- Services listening on `0.0.0.0` that should be localhost-only.

In these cases, still do not silently remediate unless the user has previously delegated emergency response authority. Summarize and ask.

## Report structure

Write findings to the KB with these sections:

1. Executive Summary (risk rating)
2. Findings (critical, high, medium, low)
3. Recommended Hardening Plan (phased)
4. Agent-Workflow Preservation table
5. Open Questions

Keep the in-chat summary to the top 3-5 risks and the ask.

## References

- `references/boundary-verification-checklist.md` — concrete commands and interpretation for distinguishing Cloudflare-fronted HTTP from directly exposed SSH/services.

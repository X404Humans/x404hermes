# Boundary Verification Checklist

Concrete commands to distinguish a Cloudflare-fronted HTTP path from a directly exposed host boundary.

## 1. Confirm the host's own public IP

```bash
curl -s --max-time 5 https://api.ipify.org
curl -s --max-time 5 https://ifconfig.me
ip addr show <primary-nic>  # usually ens3, eth0
ip route show default
```

If the host has a public IP on its NIC, it is directly reachable for any service bound to `0.0.0.0` unless a separate cloud firewall blocks it.

## 2. Map listening sockets to interfaces

```bash
sudo ss -tulnp
```

Pay attention to the **Local Address** column:

| Binding | Meaning |
|---|---|
| `127.0.0.1:PORT` | localhost only; safe from direct internet unless tunneled |
| `0.0.0.0:PORT` | all interfaces; reachable if host has public IP and no firewall |
| `*:PORT` | same as `0.0.0.0` |
| `[::]:PORT` | all interfaces IPv6 |

## 3. Verify whether a tunnel daemon is running

```bash
ps aux | grep -iE 'cloudflare|cloudflared|tunnel|warp' | grep -v grep
which cloudflared 2>/dev/null
command -v cloudflared 2>/dev/null
ls -la /etc/cloudflared /usr/local/etc/cloudflared ~/.cloudflared 2>/dev/null
systemctl list-units --type=service --no-pager | grep -iE 'cloudflare|tunnel'
```

No daemon + public IP + listening on `0.0.0.0` = direct exposure.

## 4. Confirm HTTP is Cloudflare-fronted

```bash
dig +short <hostname>
nslookup <hostname>
curl -s --max-time 5 -I https://<hostname> | grep -iE 'cf-|server'
```

Cloudflare indicators:

- DNS resolves to Cloudflare IPs (`104.21.x.x`, `172.67.x.x`, etc.).
- Response headers include `server: cloudflare`, `cf-ray`, `cf-cache-status`.

## 5. Confirm SSH is NOT Cloudflare-fronted

```bash
# Where are SSH login attempts coming from?
sudo grep -E 'Accepted|Failed password|Invalid user' /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn | head -20

# Active SSH sessions
who
w
```

If `auth.log` shows public IPs attempting SSH, SSH is directly exposed.

## 6. Check for conflicting SSH config snippets

```bash
grep -RvhE '^#|^$' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf | sort -u
```

Cloud-init sometimes drops `PasswordAuthentication yes` into `/etc/ssh/sshd_config.d/50-cloud-init.conf`. The last matching directive wins; explicit settings in `sshd_config` are safest.

## 7. Interpret the evidence

| Observation | Conclusion |
|---|---|
| HTTP resolves to Cloudflare IPs + has `cf-ray` | HTTP is Cloudflare-fronted |
| Host has public IP on NIC + sshd on `0.0.0.0:22` + auth.log shows external brute-force IPs | SSH is directly exposed to the internet |
| No `cloudflared` process and no tunnel service | No active tunnel client on the host |
| Internal service bound to `127.0.0.1` only | Safe from direct internet; protected by Caddy/tunnel reverse proxy |

## Session example: x404 VPS 2026-08-20

- Host had public IP `135.148.42.246` on `ens3`.
- `sshd` listening on `0.0.0.0:22` and `[::]:22`.
- `auth.log` showed continuous brute-force attempts from many public IPs.
- `x404.computer.ac` resolved to Cloudflare IPs and returned `server: cloudflare` headers.
- No `cloudflared` binary or service present.
- Conclusion: **HTTP/HTTPS via Cloudflare, SSH directly exposed.**

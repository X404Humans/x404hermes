# Debug handoff template for Claude Code

Use this when a runtime, KB, auth, or infra issue needs a human to debug inside the VPS with Claude Code.

## What to include

1. **Exact command that failed**
   - Paste the full command as run.

2. **Exact error output**
   - Include the complete stderr / terminal output. Do not summarize.

3. **What works / what is known**
   - Git remotes (`git remote -v`).
   - Git user config (`git config user.name`, `git config user.email`).
   - Any credential helper or stored token info (without exposing the secret).
   - Whether a cron is supposed to handle this and what its schedule is.

4. **Specific things to check**
   - Credential helper setup (`git config --list | grep credential`).
   - Stored PAT/token scope (`repo` for private repos).
   - Token expiration / rotation.
   - Whether the cron runs as the same user / environment.
   - SSH vs HTTPS remote and key availability.

5. **Goal of the debugging session**
   - One sentence on what “fixed” looks like.

## Example

**Issue:** Manual push from `/data/knowledge` to `X404Humans/x404knowledge` fails.

**Failed command:**
```bash
cd /data/knowledge && git push origin main
```

**Error output:**
```
remote: Invalid username or token.
fatal: Authentication failed for 'https://github.com/X404Humans/x404knowledge.git/'
```

**What works / known:**
- HTTPS remote to `https://github.com/X404Humans/x404knowledge.git`.
- Git user set to `x404hermes / hermes@x404humansfound.com`.
- A 5-minute git-sync cron is supposed to push automatically, but success is unverified.
- No `.git-credentials` file visible at `/data/.git-credentials`.

**Check:**
1. Is the 5-minute cron actually pushing? Check recent commits on GitHub and cron logs.
2. Where is the stored credential/token for `x404hermes`?
3. Does the token have `repo` scope for the private repo?
4. If expired, generate a new fine-grained PAT scoped to `X404Humans/x404knowledge` and update the credential helper.

**Goal:** Restore reliable automated bidirectional sync so Hermes can trust KB changes land on GitHub.

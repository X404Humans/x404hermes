---
name: x404-chief-of-staff
version: 1.0.0
description: Orchestrate group alignment, meeting digests, action tracking, and sub-agent delegation for x404 Humans Found.
metadata:
  hermes:
    tags: [x404, orchestration, chief-of-staff, meeting-digest, action-tracking, sub-agents]
    related_skills: [hermes-agent, llm-wiki, plan]
---

# x404 Chief of Staff Orchestration

How to operate as the chief of staff / orchestration agent for x404 Humans Found.

## Scope

Use this skill when:
- The user asks about group alignment, mission/objectives/commitments, or R&R.
- You are ingesting meeting notes, building agendas, or tracking action items.
- You are wiring sub-agents (research radar, meeting digest, curator, build dispatcher) to Slack channels.
- You are updating the Karpathy-style knowledgebase (`/data/knowledge`) for the group.

## Core workflow: align first, then execute, then close the loop

1. **Collect context.** Read the relevant sources in `/data/knowledge/sources/`, recent Slack history, and the wiki.
2. **Draft and confirm.** When a plan, agenda, or alignment proposal affects the group, **draft it in the KB and ask for human sign-off before writing durable files.**
3. **Execute.** After approval, make the changes and update `wiki/action-items.md`, `wiki/decisions.md`, `wiki/log.md`.
4. **Close the loop in-chat.** Summarize what was done, what is pending, and what is blocked **in the conversation thread** — do not make humans pull files from GitHub to know the state.

## Meeting operations

### Schedule convention
- Weekly sync: **Wednesday 08:00 SGT / Tuesday 20:00 ET**.
- Use the **Singapore date** for meeting folders and agendas to match the group’s YouTube conventions.

### Agenda cycle
1. **Tuesday 02:00 UTC** (24h before sync): create next-meeting folder under `sources/meeting notes/YYYY-MM-DD x404 Humans Found Sync/` and seed a proposed-agenda `.md`.
2. Post the GitHub link to `#meetings` (`C0B5T66ESGY`) and ask for edits.
3. Update the agenda file as humans give feedback in Slack or edit on GitHub.
4. After the meeting: digest any notes dropped into the folder and post a digest to `#meetings`.

### Digest format
```markdown
:x404: *Meeting Digest — x404 Humans Found Sync / YYYY-MM-DD*

*Key Decisions*
- bullet

*Action Items*
- [owner] task

*Open Questions*
- question

*Source:* `sources/meeting notes/YYYY-MM-DD x404 Humans Found Sync/...`
```

Use the Slack user ID mapping in `wiki/members.md` when pinging owners.

## Action tracking

- Registry: `/data/knowledge/wiki/action-items.md`.
- Auto-assign owners based on who spoke about a topic; humans can suggest otherwise.
- Stale-action check: flag items not updated in >7 days.
- Weekly status nudges in `#meetings`.

## Sub-agent map

| Sub-agent | Channel | Model | Responsibility |
|---|---|---|---|
| Research Radar | `<#C0BQURPSA8M>` | qwen3.5 | Daily AI infra/model-release brief |
| Meeting Digest | `<#C0B5T66ESGY>` | qwen3.5 | Summarize meeting notes, extract actions |
| Knowledge Curator | route by content | qwen3.5 | Weekly KB lint, cross-links, staleness |
| Build Dispatcher | project-specific (future) | kimi-k2.7-code | Spawn coding agents for group builds |
| Main orchestrator (you) | all channels | kimi-k2.7-code | Alignment, routing, 2-way chat |

All models must be on **ollama-cloud** unless the user explicitly adds another provider.

## Sub-agent environment isolation

When spawning isolated Hermes profiles from cron or wrapper scripts:

1. **Export `HERMES_HOME` in the launcher script** before invoking `hermes`:
   ```bash
   export HERMES_HOME=/data/runtime/hermes
   ```
2. **Symlink each profile `.env` to the runtime `.env`** so API keys propagate:
   ```bash
   ln -sf /data/runtime/hermes/.env /data/runtime/hermes/profiles/x404-meeting-prep/.env
   ln -sf /data/runtime/hermes/.env /data/runtime/hermes/profiles/x404-knowledge-curator/.env
   ```
3. **Use the CLI toolset `slack`** for reading Slack history in `hermes chat --toolsets ...`; do not use `hermes-slack`.
4. **Deliver with `hermes send --to slack:<CHANNEL>`**, not inside the chat prompt. The `slack` toolset only reads history.

Pitfall: `No usable credentials found for provider 'ollama-cloud'` from a sub-agent usually means `HERMES_HOME` is not exported or the profile `.env` symlink is missing. It does **not** mean the provider is down. See `references/isolated-sub-agent-env.md`.

## Knowledgebase cleanup rules

- `sources/` is immutable. Never modify files there.
- Synthesis lives in `wiki/`.
- Legacy files may be moved to `ops-guides/archive/` or `sources/uploads/archive/` **without renaming**.
- Always check with Zain before moving files that may be cloud-computer dependencies (`about-me.md`, `KNOWLEDGE.md`, `manifest.json`, etc.).

## Communication style

- Brief and direct.
- Cite sources and link to KB pages.
- Default to public shared channels; use threads for deep dives.
- When status is multi-step, reproduce the checklist in the chat before or after updating the file.

## Open questions file

Unresolved questions live in `/data/knowledge/wiki/open-questions.md`. Move them to `decisions.md` once ratified.

## Pitfalls

### Slack channel references
- Always use the actual Slack channel reference the user provides (e.g., `<#C0BQURPSA8M>`), **not** a human-readable display name you invent (e.g., `#research-radar`). Channel display names can be ambiguous or renamed; the ID is canonical.
- Before wiring a sub-agent or cron to post to a channel, **verify the bot is a member of that channel**. If a delivery fails with `not_in_channel`, ask the human to invite `@Hermes` before retrying.

### Plans and execution plans
- When the user asks for status on an execution plan, **repeat the completed/pending/blocked checklist in the chat** — do not make them pull the markdown file from GitHub to know the state.
- Update the KB file too, but the chat is the primary interface.

### Legacy KB files
- Do not move or rename `about-me.md`, `KNOWLEDGE.md`, `manifest.json`, or other legacy files until Zain confirms they are not cloud-computer dependencies.

### Git sync issues
- If a manual `git push` from `/data/knowledge` fails with an auth error, **do not silently assume the 5-minute cron will fix it**. Surface the failure to the human and, if asked, produce a concise repro/debug handoff for Claude Code.

## Writing repro handoffs for Claude Code

When a runtime/KB/auth issue needs a human to debug inside the VPS with Claude Code, write a one-page handoff that includes:
1. The exact command that failed.
2. The exact error output.
3. What works / what’s known (remotes, user config, cron behavior).
4. Specific things to check (credential helpers, tokens, scopes, cron env).
5. The goal of the debugging session.

Keep it terse. Paste-ready for Claude Code.

---

## Related files

- `references/model-constraints.md` — available models on ollama-cloud and selection rationale.
- `references/slack-channel-routing.md` — channel IDs and routing rules.
- `references/debug-handoff-template.md` — template for Claude Code repro handoffs.

# KB Cleanup in Shared / Cloud-Computer Environments

## When this applies

- The knowledgebase is on a shared VPS or cloud computer.
- Other tools/agents may read files in the KB root.
- You are cleaning up stale files (e.g., `about-me.md`, generic `KNOWLEDGE.md`, upload manifests).

## Steps

1. **Do not move or rename files whose consumers are unclear.** Leave them in place.
2. **Create a tracking note** in `ops-guides/` listing each suspected-legacy file and asking the infrastructure owner to confirm dependencies.
3. **Wait for explicit confirmation** before archiving.
4. **Move to an `archive/` subfolder without renaming the file.** For example:
   - `about-me.md` → `ops-guides/archive/about-me.md`
   - `KNOWLEDGE.md` → `ops-guides/archive/KNOWLEDGE.md`
5. **Log the move** in `wiki/log.md`.

## Why

Cloud-computer agents or other automation may depend on specific paths. Renaming or moving files silently can break those tools. Explicit confirmation + no rename preserves safety.

## Template tracking note

```markdown
# Cloud-Computer File Dependencies — Action Item for [Owner]

## Files to confirm
| File | Suspected purpose | Proposed action after confirmation |
|---|---|---|
| /data/knowledge/about-me.md | Cloud-computer agent identity | Move to ops-guides/archive/about-me.md |
| /data/knowledge/KNOWLEDGE.md | Cloud-computer KB schema | Move to ops-guides/archive/KNOWLEDGE.md |

## Request to [Owner]
Please confirm whether any tool reads these files. If safe, approve the archive move.
```

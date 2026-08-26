# Dealing with Deleted or Stale Agenda Files in the x404 KB

The `/data/knowledge` KB is synced to GitHub on a cron. Automated syncs can delete locally-created files if they are not committed, or can leave stale duplicate folders when the naming convention changes.

## Verification workflow
1. If the user references a KB file but it cannot be found locally, do not conclude it does not exist. Check git history: `git log --all --name-only -- "sources/meeting notes/..."`.
2. If the file exists in a previous commit but not in the working tree, inspect the commit that removed it (`git show <commit> --stat`).
3. Decide whether to restore/update the deleted file, or redirect to the canonical current file.

## Duplicate resolution
When two files exist for the same sync (e.g., ET Wednesday vs SGT Thursday date):
1. Keep the **SGT Thursday date** file as canonical.
2. Merge any unique content from the ET-dated file into the SGT-dated file.
3. Delete the ET-dated file/folder.
4. Commit, push, and update Slack links to the canonical file.

## Why this matters
In this session the user referenced `2026-08-26-proposed-agenda.md`, which was present in GitHub but had been deleted from the local working tree by an automated sync. The agent searched only the current working tree and wrongly concluded the file was only on GitHub. The correct action was to inspect git history, find the deletion, and reconcile the canonical SGT-dated file.

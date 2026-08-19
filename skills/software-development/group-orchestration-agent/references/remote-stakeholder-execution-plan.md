# Execution-Plan State for Remote Stakeholders

## When this applies

- The user reviews the workspace from a different machine than where the agent edits.
- GitHub or file sync has noticeable lag.
- The plan spans multiple sessions.
- The user explicitly says something like: "it is too much friction to wait for you to commit knowledgebase to github and pull the latest locally every single time."

## What to do

When an execution plan changes state (items completed, added, blocked), replicate the current state into the active chat or the user’s preferred sync channel as a concise list:

```text
[Plan Name] — State

COMPLETED
[x] Task A
[x] Task B

PENDING
[ ] Task C
[ ] Task D

BLOCKED
[ ] Task E — waiting on [who/what]
```

Do not wait for the user to ask. Do it whenever a material change happens.

## Why

The markdown plan file is the source of truth, but it is not the fastest way for a remote stakeholder to see status. Replicating state reduces friction and prevents the user from feeling out of sync.

## Also update the plan file

The chat summary is a mirror, not a replacement. Always update the canonical plan markdown too.

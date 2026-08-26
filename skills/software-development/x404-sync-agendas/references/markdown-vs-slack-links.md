# Markdown vs Slack Link Format for x404 Agendas

The same agenda content is published in two places with different link syntax.

## KB Markdown file
Use standard Markdown inline links with the KB path as display text:

```markdown
- A3: Zain to confirm cloud-computer dependencies. — [ops-guides/cloud-computer-file-dependencies.md](https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/cloud-computer-file-dependencies.md)
```

Rules:
- Display text must be the KB path or a short title, **never** a raw GitHub URL.
- Use `[display](URL)`, not Slack-style `<URL|display>`.
- Plain items are OK when self-explanatory (e.g., "Q6: Who drops meeting notes into the KB?").

## Slack post
Use Slack `mrkdwn` with URL-first angle-bracket links:

```text
- A3: Zain to confirm cloud-computer dependencies. — <https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/cloud-computer-file-dependencies.md|ops-guides/cloud-computer-file-dependencies.md>
```

Rules:
- Format is always `<URL|display>`, never `<display|URL>`.
- Real newlines only; do not send literal `\n` characters.

## Why the distinction matters
Pasting Slack-style links into the Markdown file causes GitHub to render the raw GitHub URL, which breaks the clean path-only display Tony expects. If the user says "raw URLs are showing," the almost-certain cause is Slack-style `<URL|text>` links in the markdown source.

## Pitfalls
- Do not use `<URL|text>` in the KB markdown file.
- Do not regress existing Markdown links to Slack-style links when editing a file.
- Do not use full GitHub URLs as link display text in either format.
- Keep the Slack message and the markdown file in sync: same sections, same order, same linked items, but the correct syntax for each medium.
